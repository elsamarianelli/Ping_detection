------------------------------------------ Davide_analysis_master.m ------------------------------------------

1) trigger time detection (with pprompts to appropriately set threhsholding), saves trigger times in excel file (optional)
2) loads EEG data- preprocesses, and runs field trip analysis - given lack of a trigger channel, cfg.trl matrix is made using trigger times extracted * sampling frequency 

------------------------------------------ extract_trigger_times.m ------------------------------------------

This script analyzes an audio recording to detect specific sound events (triggers) based on a template trigger file. It:

1) Loads the main audio file and the trigger template.
2) Computes and normalizes spectrograms for both signals.
3) Extracts dominant frequency bands from the trigger.
4) Filters the full audio based on these dominant frequencies.
5) Smooths the extracted power signal and allows manual threshold setting.
6) Plots the extracted triggers and plays back the audio with a moving cursor for validation.
7) Saves detected trigger times as a .csv file.
