# Vehicle Tester by Kravs v2.0

## Overview
Advanced vehicle testing and preview system for FiveM servers with a modern web interface. This resource allows server administrators and developers to easily preview, test, and validate custom vehicle models.

## Features
- **Vehicle Preview**: View vehicles in a controlled environment
- **Drive Testing**: 1-minute timed test drives
- **Web Interface**: Modern, responsive UI
- **Search System**: Find vehicles by name
- **Camera Controls**: Multiple view modes and free camera
- **Keyboard Shortcuts**: Quick navigation and controls
- **Configuration**: Easily customizable settings
- **Memory Management**: Proper cleanup and resource management

## Installation
1. Place the `vehiclestest` folder in your server's `resources` directory
2. Add `start vehiclestest` to your `server.cfg`
3. Restart your server

## Vehicle Management
Vehicles are stored in `data/vehicles.json`. To add or remove vehicles:
1. Edit the JSON file
- **External Configuration**: Configurable settings via config file
- **JSON Data Storage**: Vehicle list moved to external JSON file
- **Memory Management**: Proper cleanup on resource stop
- **Error Handling**: Comprehensive validation and error handling
- **Performance Optimization**: Reduced redundant code and improved efficiency
- **Modern JavaScript**: Class-based UI with proper error handling
- **Consistent Naming**: Standardized function and variable names
- **Security**: Input validation and secure practices

## Debug Mode
## Support
For issues or questions, check the console for error messages and ensure all vehicle models are properly installed on your server.
