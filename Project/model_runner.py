from tensorflow.keras.models import load_model
import numpy as np

# Load the .h5 model
model = load_model('model.h5')

# Define a function for prediction
def predict(input_data):
    # Convert input data to a numpy array
    input_data = np.array(input_data).reshape(1, -1)  # Adjust shape as per model input
    prediction = model.predict(input_data).tolist()  # Convert prediction to a list
    return prediction
