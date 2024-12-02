# Dockerfile to deploy the FastAPI app with ABSAModel and necessary files

# Base image with Python 3.9
FROM python:3.9-slim

# Set environment variables to prevent Python from writing pyc files and buffering stdout/err
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set the working directory in the container
WORKDIR /app

# Copy requirements file to container
COPY requirements.txt /app/

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py /app/
COPY modeling /app/modeling/
COPY data_manager /app/data_manager/
COPY utils /app/utils/

# Copy the model and meta.bin files (모델은 파일이 너무 커서 생략)
COPY ckpt/result_model/pytorch_model.bin /app/ckpt/result_model/
COPY ckpt/result_model/meta.bin /app/ckpt/result_model/  

# Expose the port the app runs on
EXPOSE 8000

# Run the FastAPI application
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]



