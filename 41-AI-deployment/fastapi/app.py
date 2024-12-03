from fastapi import FastAPI  # FastAPI 모듈 임포트, 웹 API 서버 구축에 사용
from pydantic import BaseModel  # 데이터 검증을 위한 Pydantic의 BaseModel 임포트
import torch  # PyTorch 라이브러리 임포트
from modeling.model import ABSAModel  # 학습한 모델 클래스 임포트
from data_manager.dataset.absa import Encoder  # Encoder 클래스 임포트 (LabelEncoder 역할)
from utils.model_utils import device_setting  # 디바이스(GPU/CPU) 설정 함수 임포트
from transformers import BertTokenizer  # BERT 토크나이저 임포트
import uvicorn  # FastAPI 서버 실행을 위한 uvicorn
import os  # 파일 경로 관리를 위한 os 모듈

# 입력 데이터 형식 정의
class InputData(BaseModel):
    text: str  # 클라이언트가 전송할 데이터 형식 정의 (text라는 문자열 필드)

app = FastAPI()  # FastAPI 앱 생성

# 디바이스 설정
device = device_setting()  # 학습된 모델을 실행할 디바이스를 설정 (GPU 또는 CPU 사용 여부 결정)

# 설정값들 적용
CONFIG = {
    'eval_fp': "./resources/data/test/",  # 평가 데이터 파일 경로 (여기서는 사용되지 않음)
    'eval_batch_size': 4,  # 평가 배치 사이즈 (여기서는 사용되지 않음)
    'init_model_path': "klue/bert-base",  # 학습에 사용된 BERT 모델 경로
    'max_length': 512,  # 토큰화된 입력 데이터의 최대 길이 설정
    'need_birnn': 0,  # BiRNN 레이어 추가 여부 (0 = 사용하지 않음, 1 = 사용)
    'print_sample': 1,  # 샘플 출력 여부 (여기서는 사용되지 않음)
    'sentiment_drop_ratio': 0.3,  # Sentiment 예측에 사용할 Dropout 비율 (오버피팅 방지용)
    'aspect_drop_ratio': 0.3,  # Aspect 예측에 사용할 Dropout 비율 (오버피팅 방지용)
    'sentiment_in_feature': 768,  # Sentiment 입력 피처 사이즈 (BERT의 출력 크기와 동일)
    'aspect_in_feature': 768,  # Aspect 입력 피처 사이즈 (BERT의 출력 크기와 동일)
    'base_path': "./ckpt/result_model/",  # 모델 파일 및 인코더 파일이 저장된 경로
    'label_info_file': "meta.bin",  # 인코더 파일 이름 (레이블 정보 저장)
    'out_model_path': "pytorch_model.bin"  # 학습된 모델 파일 이름
}

# 토크나이저 로드
# 학습에 사용된 BERT 토크나이저를 로드하여 입력 데이터를 동일한 방법으로 전처리
tokenizer = BertTokenizer.from_pretrained(CONFIG['init_model_path'])  # 모델 경로에서 BERT 토크나이저 로드

# Encoder 로드
# 학습된 레이블 인코더를 로드하여 예측 결과를 실제 레이블로 변환하는 데 사용
META_PATH = os.path.join(CONFIG['base_path'], CONFIG['label_info_file'])  # 인코더 파일의 경로 설정
enc = Encoder()  # Encoder 객체 생성
enc.load_encoder(META_PATH)  # 인코더 파일 로드 (학습된 레이블 정보 로드)
enc_aspect, enc_aspect2, enc_sentiment = enc.get_encoder()  # 감정 및 속성 레이블 인코더 가져오기

# 클래스 수 계산
# 감정 및 속성의 클래스 수를 계산하여 모델에 전달
num_aspect = len(list(enc_aspect.classes_))  # 일반 속성 클래스 수 계산
num_aspect2 = len(list(enc_aspect2.classes_))  # 대분류 속성 클래스 수 계산
num_sentiment = len(list(enc_sentiment.classes_))  # 감정 클래스 수 계산

# 모델 로드
# 학습된 모델을 로드하여 추론에 사용
MODEL_PATH = os.path.join(CONFIG['base_path'], CONFIG['out_model_path'])  # 모델 파일 경로 설정
model = ABSAModel(
    config={
        'init_model_path': CONFIG['init_model_path'],  # 초기 BERT 모델 경로 설정
        'sentiment_in_feature': CONFIG['sentiment_in_feature'],  # Sentiment 예측 입력 피처 크기 설정
        'aspect_in_feature': CONFIG['aspect_in_feature'],  # Aspect 예측 입력 피처 크기 설정
        'sentiment_drop_ratio': CONFIG['sentiment_drop_ratio'],  # Sentiment 예측 Dropout 비율 설정
        'aspect_drop_ratio': CONFIG['aspect_drop_ratio'],  # Aspect 예측 Dropout 비율 설정
        'need_birnn': CONFIG['need_birnn']  # BiRNN 사용 여부 설정
    },
    num_sentiment=num_sentiment,  # 감정 클래스 수 설정
    num_aspect=num_aspect,  # 일반 속성 클래스 수 설정
    num_aspect2=num_aspect2,  # 대분류 속성 클래스 수 설정
    need_birnn=bool(CONFIG['need_birnn'])  # BiRNN 사용 여부를 불리언 값으로 설정
)

# 모델의 가중치 로드
# 학습된 파라미터를 모델에 적용하고, 추론을 위한 평가 모드로 설정
model.load_state_dict(torch.load(MODEL_PATH, map_location=device))  # 학습된 모델 파라미터 로드\model.to(device)  # 모델을 GPU 또는 CPU로 전송
model.eval()  # 평가 모드로 설정 (드롭아웃 등을 비활성화하여 추론 정확도 향상)

# 추론 엔드포인트 정의
@app.post("/predict")
async def predict(data: InputData):
    text = data.text  # 클라이언트로부터 받은 텍스트 데이터
    # 입력 데이터 전처리
    # 클라이언트로부터 받은 텍스트를 BERT 토크나이저를 사용해 토큰화 및 패딩/트렁케이션
    inputs = tokenizer(
        text,
        padding='max_length',  # 설정한 최대 길이만큼 패딩 (짧은 입력을 고정된 길이로 맞춤)
        truncation=True,  # 설정된 최대 길이 이상은 잘라냄 (긴 입력 데이터 잘라냄)
        max_length=CONFIG['max_length'],  # 최대 길이 설정 (512 토큰)
        return_tensors='pt'  # PyTorch 텐서 형태로 반환 (모델에 입력하기 위해 필요)
    )

    # 입력 데이터를 디바이스로 이동 (GPU 또는 CPU)
    inputs = {k: v.to(device) for k, v in inputs.items()}  # 입력 텐서를 설정된 디바이스로 이동

    # 모델 예측
    with torch.no_grad():  # 그래디언트 계산을 하지 않음 (추론 시에는 필요 없음으로 성능 향상)
        outputs = model(**inputs)  # 모델에 입력 데이터를 전달하여 예측 수행

    # 결과 후처리
    # 모델이 예측한 감정, 속성, 속성2에 대한 로짓을 추출
    sentiment_logits = outputs['sentiment']  # 감정 예측 로짓
    aspect_logits = outputs['aspect']  # 일반 속성 예측 로짓
    aspect2_logits = outputs['aspect2']  # 대분류 속성 예측 로짓

    # 각 로짓에서 최댓값의 인덱스를 선택하여 예측된 클래스 인덱스를 얻음
    sentiment_pred = torch.argmax(sentiment_logits, dim=1).cpu().numpy()  # 감정 예측 인덱스 추출
    aspect_pred = torch.argmax(aspect_logits, dim=1).cpu().numpy()  # 일반 속성 예측 인덱스 추출
    aspect2_pred = torch.argmax(aspect2_logits, dim=1).cpu().numpy()  # 대분류 속성 예측 인덱스 추출

    # 예측된 인덱스를 실제 레이블로 변환
    sentiment_label = enc_sentiment.inverse_transform(sentiment_pred)[0]  # 감정 인덱스를 실제 레이블로 변환
    aspect_label = enc_aspect.inverse_transform(aspect_pred)[0]  # 일반 속성 인덱스를 실제 레이블로 변환
    aspect2_label = enc_aspect2.inverse_transform(aspect2_pred)[0]  # 대분류 속성 인덱스를 실제 레이블로 변환

    # 예측 결과를 JSON 형태로 반환
    return {
        "sentiment": sentiment_label,  # 감정 레이블 (긍정, 부정 등)
        "aspect": aspect_label,  # 일반 속성 레이블 (제품, 서비스 등)
        "aspect2": aspect2_label  # 대분류 속성 레이블
    }

# FastAPI 애플리케이션 실행
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)  # 서버를 8000번 포트에서 실행 (외부에서 접근 가능)
