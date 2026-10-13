from flask import Flask, request, jsonify
import numpy as np
from PIL import Image
import torchvision.transforms as transforms
import io

app = Flask(__name__)

# Preprocessing function
def preprocess_image(image_bytes):
    # Load image from bytes
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    
    # Preprocess the image
    transform = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])
    image_tensor = transform(image).unsqueeze(0)  # Add batch dimension
    return image_tensor.numpy()

# API endpoint for preprocessing
@app.route('/preprocess', methods=['POST'])
def preprocess():
    if 'file' not in request.files:
        return jsonify({"error": "No file provided"}), 400
    
    file = request.files['file']
    image_bytes = file.read()
    
    # Preprocess the image
    preprocessed_data = preprocess_image(image_bytes)
    
    # Convert the preprocessed data to a list (for JSON serialization)
    preprocessed_list = preprocessed_data.flatten().tolist()
    
    return jsonify({"preprocessed_data": preprocessed_list})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)