# Ping_detection
This script analyzes an audio recording to detect specific sound events (triggers) based on a template trigger file. It:

Loads the main audio file and the trigger template.
Computes and normalizes spectrograms for both signals.
Extracts dominant frequency bands from the trigger.
Filters the full audio based on these dominant frequencies.
Smooths the extracted power signal and allows manual threshold setting.
Plots the extracted triggers and plays back the audio with a moving cursor for validation.
Saves detected trigger times as a .csv file.
