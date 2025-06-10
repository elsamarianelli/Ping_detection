# IFOF iEEG and accompanying video processing
Code to align trigger times extracted from audio files with iEEG traces, clean stimulation periods, and segment the EEG data into trials for further analysis (e.g. FT)

## Notes 
Still need too: 
- look at interictal spikes
- apply stim cleaning across all channels?
- FT on epoched by trials

## Getting Started

The main script is:

### `Davide_analysis_master.m`

Run this to:
- Load EEG and audio data
- Extract ping trigger times from `.wav` files
- Detect stimulation periods in EEG traces
- Epoch the EEG into trials (stim vs non-stim)
- Optionally clean artifacts from stimulation periods

---

## Function Overview

| Function                        | Description                                                          |
|--------------------------------|----------------------------------------------------------------------|
| `extract_trigger_times`        | Detects   ping times from an audio file                             |
| `extract_stim_clusters`        | Identifies sustained high-amplitude EEG stimulation periods         |
| `clean_stimulation_periods`    | Removes and interpolates stimulation artifacts in a single EEG trace |
| `make_epoching_trial_cfg`      | Builds FieldTrip-style trial configs    from ping times            |
| `epoch_with_stim_and_trig_times` | Automatically creates stim vs non-stim trial groups               |
| `plot_EEG_with_triggers`       | Overlays ping times on EEG trace for inspection                     |
| `save_trig_and_stim_times`     | Saves ping/stim times into an Excel sheet                           |
| `playback_with_cursor_new`     | Plays audio with interactive cursor and speed controls              |

---

## Dependencies

- [FieldTrip Toolbox](https://www.fieldtriptoolbox.org/)
- Signal Processing Toolbox
 

