# Repository Security Audit & Credential Handling Report

This document reports the findings of the repository security audit conducted on the canonical repository.

---

## 1. Audit Summary
A repository-wide recursive audit was conducted on all source code files, configuration files, and Arduino scripts in:
* **Canonical Repository:** `D:\SIDT_MAtlab\Smart_Irrigation_Digital_Twin-main`

### Findings
* **No active secrets, WiFi credentials, or private ThingSpeak API keys were found in any code file.**
* All credentials in the canonical source files have been successfully sanitized and replaced with secure placeholder variables (e.g., `YOUR_WRITE_API_KEY`, `YOUR_WIFI_NAME`).
* The local configuration header `hardware_iot/esp32/config.h` was audited and contains only generic placeholders. This file is properly ignored by Git via the `.gitignore` configuration.

---

## 2. Credentials Verification Details

| File Path | Audited Line / Variable | Content / Status |
| :--- | :--- | :--- |
| `hardware_iot/esp32/config.h` | `WIFI_SSID` / `WIFI_PASSWORD` | Verified Sanitized (`"YOUR_WIFI_NAME"`, `"YOUR_WIFI_PASSWORD"`) |
| `hardware_iot/esp32/config.h` | `THINGSPEAK_WRITE_KEY` / `_READ_KEY` | Verified Sanitized (`"YOUR_WRITE_API_KEY"`, `"YOUR_READ_API_KEY"`) |
| `hardware_iot/matlab_realtime/send_irrigation_cmd.m` | `setenv('THINGSPEAK_WRITE_KEY', ...)` | Verified Sanitized (`'YOUR_WRITE_API_KEY'`) |
| `hardware_iot/matlab_realtime/live_digital_twin.m` | `setenv('THINGSPEAK_WRITE_KEY', ...)` | Verified Sanitized (`'YOUR_WRITE_KEY'`) |

---

## 3. Recommended Environment-Variable Configuration

To prevent security leaks, credentials should **never** be saved to the workspace scripts or committed to Git. Instead, they should be set locally in the MATLAB workspace environment using `setenv` in the Command Window before running.

### Setting credentials in MATLAB Command Window:
```matlab
% Run these commands in the MATLAB Command Window before executing the script
setenv('THINGSPEAK_CHANNEL_ID', '3213225');        % Replace with your actual Channel ID
setenv('THINGSPEAK_READ_KEY',   'VG7AS11*********'); % Masked active Read API Key
setenv('THINGSPEAK_WRITE_KEY',  'YTK1QPQ*********'); % Masked active Write API Key
```

### Retrieving credentials in MATLAB code:
The real-time script retrieves these values dynamically from the environment without storing them in text files:
```matlab
channelID = str2double(getenv('THINGSPEAK_CHANNEL_ID'));
readKey   = getenv('THINGSPEAK_READ_KEY');
writeKey  = getenv('THINGSPEAK_WRITE_KEY');
```

---

## 4. Git Ignore Policy
The `.gitignore` file includes rules to ensure local configurations are not committed:
```
# Exclude config.h which contains local credentials
config.h

# Exclude MATLAB temporary scripts and backup files
*.asv
*.m~
slprj/
```
This guarantees WiFi network credentials and private keys remain secure on the developer's local machine.
