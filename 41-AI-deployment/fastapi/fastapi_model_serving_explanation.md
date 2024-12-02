# FastAPI를 사용한 PyTorch 모델 HTTP 서비스 제공

물론입니다! 주신 코드에 자세한 주석을 추가하여 설명해 드리겠습니다. 이 코드에서는 PyTorch로 학습된 인공지능 모델을 FastAPI를 사용하여 HTTP 서비스로 제공하고 있습니다. 클라이언트는 HTTP 요청을 통해 모델을 호출하여 예측을 받을 수 있습니다.

```python
# app.py
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
device = device_setting()  # 학습된 모델을 실행할 디바이스를 설정 (GPU 또는 CPU)

# 설정값들 적용
CONFIG = {
    'eval_fp': "./resources/data/test/",  # 평가 데이터 파일 경로 (여기서는 사용되지 않음)
    'eval_batch_size': 4,  # 평가 배치 사이즈 (여기서는 사용되지 않음)
    'init_model_path': "klue/bert-base",  # 학습에 사용된 BERT 모델 경로
    'max_length': 512,  # 토큰화된 입력 데이터의 최대 길이 설정
    'need_birnn': 0,  # BiRNN 레이어 추가 여부 (0 = 사용하지 않음)
    'print_sample': 1,  # 샘플 출력 여부 (여기서는 사용되지 않음)
    'sentiment_drop_ratio': 0.3,  # Sentiment 예측에 사용할 Dropout 비율
    'aspect_drop_ratio': 0.3,  # Aspect 예측에 사용할 Dropout 비율
    'sentiment_in_feature': 768,  # Sentiment 입력 피처 사이즈
    'aspect_in_feature': 768,  # Aspect 입력 피처 사이즈
    'base_path': "./ckpt/result_model/",  # 모델 파일 및 인코더 파일이 저장된 경로
    'label_info_file': "meta.bin",  # 인코더 파일 이름 (레이블 정보 저장)
    'out_model_path': "pytorch_model.bin"  # 학습된 모델 파일 이름
}

# 토크나이저 로드
# 학습에 사용된 BERT 토크나이저를 로드하여 입력 데이터를 동일한 방법으로 전처리
tokenizer = BertTokenizer.from_pretrained(CONFIG['init_model_path'])

# Encoder 로드
# 학습된 레이블 인코더를 로드하여 예측 결과를 실제 레이블로 변환하는 데 사용
META_PATH = os.path.join(CONFIG['base_path'], CONFIG['label_info_file'])
enc = Encoder()  # Encoder 객체 생성
enc.load_encoder(META_PATH)  # 인코더 파일 로드
enc_aspect, enc_aspect2, enc_sentiment = enc.get_encoder()  # 감정 및 속성 레이블 인코더 가져오기

# 클래스 수 계산
# 감정 및 속성의 클래스 수를 계산하여 모델에 전달
num_aspect = len(list(enc_aspect.classes_))
num_aspect2 = len(list(enc_aspect2.classes_))
num_sentiment = len(list(enc_sentiment.classes_))

# 모델 로드
# 학습된 모델을 로드하여 추론에 사용
MODEL_PATH = os.path.join(CONFIG['base_path'], CONFIG['out_model_path'])
model = ABSAModel(
    config={
        'init_model_path': CONFIG['init_model_path'],
        'sentiment_in_feature': CONFIG['sentiment_in_feature'],
        'aspect_in_feature': CONFIG['aspect_in_feature'],
        'sentiment_drop_ratio': CONFIG['sentiment_drop_ratio'],
        'aspect_drop_ratio': CONFIG['aspect_drop_ratio'],
        'need_birnn': CONFIG['need_birnn']
    },
    num_sentiment=num_sentiment,
    num_aspect=num_aspect,
    num_aspect2=num_aspect2,
    need_birnn=bool(CONFIG['need_birnn'])
)

# 모델의 가중치 로드
# 학습된 파라미터를 모델에 적용하고, 추론을 위한 평가 모드로 설정
model.load_state_dict(torch.load(MODEL_PATH, map_location=device))
model.to(device)  # 모델을 GPU 또는 CPU로 전송
model.eval()  # 평가 모드로 설정 (드롭아웃 등을 비활성화)

# 추론 엔드포인트 정의
@app.post("/predict")
def predict(data: InputData):
    text = data.text  # 클라이언트로부터 받은 텍스트 데이터
    # 입력 데이터 전처리
    # 클라이언트로부터 받은 텍스트를 BERT 토크나이저를 사용해 토큰화 및 패딩/트렁케이션
    inputs = tokenizer(
        text,
        padding='max_length',  # 설정한 최대 길이만큼 패딩
        truncation=True,  # 설정된 최대 길이 이상은 잘라냄
        max_length=CONFIG['max_length'],  # 최대 길이 설정
        return_tensors='pt'  # PyTorch 텐서 형태로 반환
    )

    # 입력 데이터를 디바이스로 이동 (GPU 또는 CPU)
    inputs = {k: v.to(device) for k, v in inputs.items()}

    # 모델 예측
    with torch.no_grad():  # 그래디언트 계산을 하지 않음 (추론 시에는 필요 없음)
        outputs = model(**inputs)

    # 결과 후처리
    # 모델이 예측한 감정, 속성, 속성2에 대한 로짓을 추출
    sentiment_logits = outputs['sentiment']
    aspect_logits = outputs['aspect']
    aspect2_logits = outputs['aspect2']

    # 각 로짓에서 최댓값의 인덱스를 선택하여 예측된 클래스 인덱스를 얻음
    sentiment_pred = torch.argmax(sentiment_logits, dim=1).cpu().numpy()
    aspect_pred = torch.argmax(aspect_logits, dim=1).cpu().numpy()
    aspect2_pred = torch.argmax(aspect2_logits, dim=1).cpu().numpy()

    # 예측된 인덱스를 실제 레이블로 변환
    sentiment_label = enc_sentiment.inverse_transform(sentiment_pred)[0]
    aspect_label = enc_aspect.inverse_transform(aspect_pred)[0]
    aspect2_label = enc_aspect2.inverse_transform(aspect2_pred)[0]

    # 예측 결과를 JSON 형태로 반환
    return {
        "sentiment": sentiment_label,  # 감정 레이블 (긍정, 부정 등)
        "aspect": aspect_label,  # 일반 속성 레이블 (제품, 서비스 등)
        "aspect2": aspect2_label  # 대분류 속성 레이블
    }

# FastAPI 애플리케이션 실행
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)  # 서버를 8000번 포트에서 실행
```

## 요약 설명
### API 구축 및 모델 로드
- **FastAPI**를 사용하여 API 서버를 구축했습니다. `app = FastAPI()`로 앱을 생성하고, `@app.post("/predict")`로 추론 엔드포인트를 정의했습니다.
- 모델(`ABSAModel`)과 **토크나이저**, **레이블 인코더**(`Encoder`)를 로드하여 입력을 처리하고 예측할 수 있도록 설정했습니다.

### 예측 요청 처리 (`/predict`)
- 클라이언트로부터 받은 텍스트 데이터를 **BERT 토크나이저**를 사용해 전처리합니다.
- **PyTorch 모델**을 사용해 텍스트에 대해 감정과 속성을 예측합니다.
- 예측 결과를 **인코더**를 통해 실제 레이블로 변환하여 클라이언트에 반환합니다.

### HTTP 서비스로 제공
- 이 API는 HTTP 요청을 통해 클라이언트로부터 데이터를 받고, 예측을 수행한 후 결과를 JSON 형태로 반환합니다.
- **FastAPI**는 비동기 방식으로 동작하며, `/predict` 엔드포인트를 사용해 HTTP POST 요청을 통해 데이터를 받을 수 있습니다.
- 서버를 실행하려면 `uvicorn`을 사용해 `python app.py` 명령으로 컨테이너를 실행하면 됩니다.

### 클라이언트 사용 예시
- 클라이언트는 이 API에 텍스트를 입력하여 감정 및 속성 분석 결과를 받을 수 있습니다.
- 예를 들어, `curl`을 사용하여 다음과 같이 요청할 수 있습니다:
  ```bash
  curl -X POST "http://localhost:8000/predict" -H "Content-Type: application/json" -d '{"text": "이 제품 정말 좋아요!"}'
  ```
- 서버는 감정(긍정/부정)과 속성(제품, 서비스 등) 정보를 반환합니다.

### Docker로 배포
- **Dockerfile**을 작성하여 이 서비스를 도커 이미지로 빌드한 후, 해당 이미지를 컨테이너로 실행해 언제 어디서나 접근 가능한 HTTP 서비스로 배포할 수 있습니다.

이렇게 인공지능 모델을 **FastAPI**로 감싸서 HTTP 서비스로 제공하게 되면, 웹 애플리케이션, 모바일 앱, 또는 다른 서비스에서 쉽게 인공지능 모델의 예측 기능을 사용할 수 있습니다.

## 샘플 요청 및 예시 응답
### 요청 예시
```bash
curl -X POST "http://localhost:8000/predict" -H "Content-Type: application/json" -d '{"text": "이 제품 정말 좋아요!"}'
```

### 예시 응답
```json
{
    "sentiment": "긍정",       // 감정 레이블: 긍정적이라는 예측
    "aspect": "제품",          // 속성 레이블: 제품 관련 평가라는 예측
    "aspect2": "기능성"        // 대분류 속성 레이블: 기능성에 관한 평가라는 예측
}
```

### 결과 설명
- **"sentiment": "긍정"**: 모델은 입력된 텍스트에 대해 긍정적인 평가라고 예측했습니다. 감정 레이블은 "긍정", "부정", "중립" 등이 될 수 있습니다.
- **"aspect": "제품"**: 모델은 이 문장이 제품에 관한 것이라고 예측했습니다. 속성 레이블은 "제품", "서비스", "가격", "배송" 등과 같은 다양한 속성으로 나뉠 수 있습니다.
- **"aspect2": "기능성"**: 제품의 기능적인 면에 대한 평가라는 예측을 나타냅니다. 대분류 속성은 "기능성", "품질", "디자인", "편리성" 등으로 나눌 수 있습니다.

### 추가 예시
- 요청: `배송이 너무 느렸어요.`
  ```bash
  curl -X POST "http://localhost:8000/predict" -H "Content-Type: application/json" -d '{"text": "배송이 너무 느렸어요."}'
  ```
  결과:
  ```json
  {
      "sentiment": "부정",        // 감정 레이블: 부정적인 평가
      "aspect": "배송",          // 속성 레이블: 배송과 관련된 문제
      "aspect2": "속도"          // 대분류 속성 레이블: 배송 속도가 느리다는 평가
  }
  ```

- 요청: `고객 서비스가 훌륭했어요!`
  ```bash
  curl -X POST "http://localhost:8000/predict" -H "Content-Type: application/json" -d '{"text": "고객 서비스가 훌륭했어요!"}'
  ```
  결과:
  ```json
  {
      "sentiment": "긍정",       // 감정 레이블: 긍정적인 평가
      "aspect": "서비스",        // 속성 레이블: 고객 서비스와 관련된 평가
      "aspect2": "응대 품질"     // 대분류 속성 레이블: 서비스 응대의 품질에 대한 평가
  }
  ```

이 예측 결과는 모델이 학습된 데이터에 따라 결정됩니다. 모델은 과거의 데이터에서 다양한 리뷰와 평가를 학습하여, 새로운 텍스트가 입력될 때 이 텍스트의 감정 및 특정 속성(제품, 서비스, 배송 등)을 예측할 수 있습니다.

- **감정 분석**: 입력된 문장이 긍정적인지 부정적인지 중립적인지를 예측합니다.
- **속성 분류**: 문장이 어떤 속성에 대해 이야기하고 있는지를 예측합니다(예: 제품, 서비스, 가격).
- **대분류 속성**: 속성을 조금 더 세부적으로 분류하여 제품의 기능성, 디자인, 서비스의 응대 품질 등으로 나눕니다.

결과는 JSON 형태로 반환되므로 클라이언트에서 쉽게 받아서 사용하거나 추가 처리를 할 수 있습니다.

> 실제 결과는 모델이 학습한 데이터와 그 성능에 따라 다를 수 있습니다. 예시로 제시한 결과는 이해를 돕기 위한 가상의 결과이며, 특정 데이터셋으로 학습된 모델의 정확도에 따라 다르게 나올 수 있습니다.
