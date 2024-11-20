# PetSentry: Automated Pet Care
PetSentry is an automated remote pet care sytem. In this project, 
I was responsible for creating the Android app for our system.
The Android app is written in Kotlin.

### Responsibilities
* Everything related to the Android app. Including but not limited to:  
  * Firebase integration:  
    * User authentication  
      * Register and log in via email and password.  
    * Realtime database  
      * Get sensor data and event logs, and send commands.  
    * Storage  
      * Download “.wav” files of loud noise events.  
  * Access to the live stream and previously recorded live streams from Vimeo.  
  * Real-time notifications.  
  * User interface and user experience design.  
  * Bluetooth communications with Raspberry Pi.  
* Raspberry Pi:  
  * Bluetooth communications with Android app.  
  * Run PetSentry-related code at startup (using the cron service).

## Navigation
- [The Report](PetSentry-report.pdf)
- [The Code](PetSentry-code.kt)
