from fastapi import FastAPI  # FastAPI 모듈 임포트, 웹 API 서버 구축에 사용
from pydantic import BaseModel  # 데이터 검증을 위한 Pydantic의 BaseModel 임포트
import os  # 파일 경로 관리를 위한 os 모듈
from vllm import AsyncLLMEngine  # vLLM Async LLM 엔진을 임포트
import uvicorn  # FastAPI 서버 실행을 위한 uvicorn

# 입력 데이터 형식 정의
class InputData(BaseModel):
    text: str  # 클라이언트가 전송할 데이터 형식 정의 (text라는 문자열 필드)

# 설정값들 적용
CONFIG = {
    'init_model_path': "klue/bert-base",  # 학습에 사용된 BERT 모델 경로
    'base_path': "./ckpt/result_model/",  # 모델 파일 및 인코더 파일이 저장된 경로
    'out_model_path': "pytorch_model.bin",  # 학습된 모델 파일 이름
    'max_length': 512,  # 토큰화된 입력 데이터의 최대 길이 설정
}

# FastAPI 앱 생성
app = FastAPI()

# vLLM Async LLM 엔진 생성
# 학습된 모델 파일 경로 설정
MODEL_PATH = os.path.join(CONFIG['base_path'], CONFIG['out_model_path'])

# vLLM의 AsyncLLMEngine 인스턴스 생성, GPU 노드를 사용하여 모델 로드 및 추론
llm_engine = AsyncLLMEngine(model_path=MODEL_PATH, tokenizer_path=CONFIG['init_model_path'])

# 추론 엔드포인트 정의
@app.post("/predict")
async def predict(data: InputData):
    text = data.text  # 클라이언트로부터 받은 텍스트 데이터
    
    # vLLM 엔진을 사용해 입력 데이터를 추론합니다.
    results = await llm_engine.generate(
        prompts=[text],
        max_tokens=CONFIG['max_length'],
        top_p=0.9,  # 필요에 따라 top_p 또는 다른 생성 파라미터를 설정 가능
        temperature=0.7
    )
    
    # 예측 결과를 JSON 형태로 반환
    response = {
        "sentiment": results[0]['sentiment'],
        "aspect": results[0]['aspect'],
        "aspect2": results[0]['aspect2']
    }
    return response

# FastAPI 애플리케이션 실행
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)  # 서버를 8000번 포트에서 실행

# 필요한 패키지 설치 명령어
# 1. FastAPI 설치
# pip install fastapi

# 2. Uvicorn 설치 (서버 실행을 위해)
# pip install uvicorn

# 3. vLLM 설치
# pip install vllm

# 4. Transformers 설치 (토크나이저 로드를 위해 필요할 수 있음)
# pip install transformers

# 5. 기타 필요 패키지
# pip install torch pydantic
