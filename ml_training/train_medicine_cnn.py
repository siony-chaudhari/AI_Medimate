# ===============================================
# train_medicine_cnn.py
# Transfer Learning on Medicine Images using MobileNetV2
# ===============================================

import os
import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.models import Model
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D, Dropout
from tensorflow.keras.callbacks import EarlyStopping, ReduceLROnPlateau
import matplotlib.pyplot as plt

# --- PATH SETTINGS ---
BASE_DIR = "/Users/siony/AndroidStudioProjects/ai_medimate/ml_training/dataset"
TRAIN_DIR = os.path.join(BASE_DIR, "train")
VALID_DIR = os.path.join(BASE_DIR, "valid")

# --- IMAGE SETTINGS ---
IMG_SIZE = 224  # MobileNetV2 default input size
BATCH_SIZE = 32
EPOCHS = 20

# --- DATA AUGMENTATION ---
train_datagen = ImageDataGenerator(
    rescale=1.0/255,
    rotation_range=20,
    width_shift_range=0.2,
    height_shift_range=0.2,
    zoom_range=0.2,
    shear_range=0.15,
    horizontal_flip=True,
    fill_mode='nearest'
)

val_datagen = ImageDataGenerator(rescale=1.0/255)

train_data = train_datagen.flow_from_directory(
    TRAIN_DIR,
    target_size=(IMG_SIZE, IMG_SIZE),
    batch_size=BATCH_SIZE,
    class_mode='categorical'
)

val_data = val_datagen.flow_from_directory(
    VALID_DIR,
    target_size=(IMG_SIZE, IMG_SIZE),
    batch_size=BATCH_SIZE,
    class_mode='categorical'
)

# --- BASE MODEL (TRANSFER LEARNING) ---
base_model = MobileNetV2(weights='imagenet', include_top=False, input_shape=(IMG_SIZE, IMG_SIZE, 3))
base_model.trainable = False  # freeze pretrained layers

# --- ADD CUSTOM CLASSIFICATION HEAD ---
x = base_model.output
x = GlobalAveragePooling2D()(x)
x = Dense(512, activation='relu')(x)
x = Dropout(0.5)(x)
outputs = Dense(train_data.num_classes, activation='softmax')(x)
model = Model(inputs=base_model.input, outputs=outputs)

# --- COMPILE MODEL ---
model.compile(optimizer=tf.keras.optimizers.Adam(learning_rate=0.0005),
              loss='categorical_crossentropy',
              metrics=['accuracy'])

model.summary()

# --- CALLBACKS ---
early_stop = EarlyStopping(monitor='val_accuracy', patience=5, restore_best_weights=True)
reduce_lr = ReduceLROnPlateau(monitor='val_loss', factor=0.2, patience=3, verbose=1)

# --- TRAIN MODEL ---
history = model.fit(
    train_data,
    validation_data=val_data,
    epochs=EPOCHS,
    callbacks=[early_stop, reduce_lr]
)

# --- UNFREEZE TOP LAYERS FOR FINE-TUNING ---
base_model.trainable = True
fine_tune_at = len(base_model.layers) // 2  # unfreeze top 50%
for layer in base_model.layers[:fine_tune_at]:
    layer.trainable = False

model.compile(optimizer=tf.keras.optimizers.Adam(learning_rate=1e-5),
              loss='categorical_crossentropy',
              metrics=['accuracy'])

fine_tune_history = model.fit(
    train_data,
    validation_data=val_data,
    epochs=10,
    callbacks=[early_stop, reduce_lr]
)

# --- PLOT TRAINING RESULTS ---
plt.plot(history.history['accuracy'] + fine_tune_history.history['accuracy'], label='train acc')
plt.plot(history.history['val_accuracy'] + fine_tune_history.history['val_accuracy'], label='val acc')
plt.legend()
plt.title("Training Accuracy (Transfer Learning + Fine-tuning)")
plt.show()

# --- SAVE MODEL ---
model.save("medicine_mobilenetv2.h5")
print("✅ Model saved as medicine_mobilenetv2.h5")

# --- CONVERT TO TFLITE ---
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()
with open("medicine_mobilenetv2.tflite", "wb") as f:
    f.write(tflite_model)
print("✅ Converted to TensorFlow Lite: medicine_mobilenetv2.tflite")
