class VehicleTesterUI {
    constructor() {
        this.currentVehicle = '';
        this.currentIndex = 1;
        this.totalVehicles = 1;
        this.driveTestTimer = null;
        this.driveTestSeconds = 60;
        this.isDebugMode = false;
        
        this.init();
    }
    
    init() {
        if (this.isDebugMode) {
            console.log('Initializing VehicleTesterUI...');
        }
        this.setupMessageHandler();
        this.setupButtonListeners();
        this.setupInputListeners();
        this.setupKeyboardListeners();
        if (this.isDebugMode) {
            console.log('VehicleTesterUI initialization complete');
        }
    }
    
    setupMessageHandler() {
        window.addEventListener('message', (event) => {
            try {
                const data = event.data;
                if (!data || !data.type) return;
                
                switch (data.type) {
                    case 'toggleUI':
                        this.handleToggleUI(data);
                        break;
                    case 'updateVehicle':
                        this.updateVehicleInfo(data.vehicle, data.index, data.total);
                        break;
                    case 'startDriveTest':
                        this.startDriveTest();
                        break;
                    case 'endDriveTest':
                        this.endDriveTest();
                        break;
                    case 'startDriveTestTimer':
                        this.showDriveTestTimer(data.duration);
                        break;
                    case 'updateTimer':
                        this.updateDriveTestTimer(data.remainingTime);
                        break;
                    case 'endDriveTestTimer':
                        this.hideDriveTestTimer();
                        break;
                    default:
                        if (this.isDebugMode) {
                            console.warn('Unknown message type:', data.type);
                        }
                }
            } catch (error) {
                if (this.isDebugMode) {
                    console.error('Error handling message:', error);
                }
            }
        });
    }
    
    handleToggleUI(data) {
        if (data.show) {
            this.showUI();
            this.updateVehicleInfo(data.vehicle, data.index, data.total);
        } else {
            this.hideUI();
        }
    }
    
    showUI() {
        const uiElement = document.getElementById('vehicle-ui');
        if (uiElement) {
            uiElement.classList.remove('hidden');
            const timerElement = document.getElementById('drive-test-timer');
            if (timerElement) {
                timerElement.classList.add('hidden');
            }
        }
    }
    
    hideUI() {
        const uiElement = document.getElementById('vehicle-ui');
        if (uiElement) {
            uiElement.classList.add('hidden');
        }
        this.sendRequest('hideUI', {});
    }
    
    closeUI() {
        this.hideUI();
        this.sendRequest('closeUI', {});
    }
    
    updateVehicleInfo(vehicle, index, total) {
        if (!vehicle || !index || !total) {
            if (this.isDebugMode) {
                console.warn('Invalid vehicle info:', { vehicle, index, total });
            }
            return;
        }
        
        this.currentVehicle = vehicle;
        this.currentIndex = parseInt(index) || 1;
        this.totalVehicles = parseInt(total) || 1;
        
        this.updateUIElements(vehicle, this.currentIndex, this.totalVehicles);
    }
    
    updateUIElements(vehicle, index, total) {
        const elements = {
            'vehicle-name': vehicle || 'Vehicle not found',
            'vehicle-index': index,
            'vehicle-index-display': index,
            'vehicle-total': total
        };
        
        for (const [id, value] of Object.entries(elements)) {
            const element = document.getElementById(id);
            if (element) {
                if (element.tagName === 'INPUT') {
                    element.value = value;
                } else {
                    element.textContent = value;
                }
            }
        }
    }
    
    sendCameraCommand(command) {
        if (!command) return;
        this.sendRequest('cameraCommand', { command });
    }
    
    startDriveTest() {
        if (this.isDebugMode) {
            console.log("Starting drive test...");
        }
        
        const timerElement = document.getElementById('drive-test-timer');
        if (timerElement) {
            timerElement.classList.remove('hidden');
        }
        
        this.driveTestSeconds = 60;
        this.updateTimerDisplay();
        
        if (this.driveTestTimer) {
            clearInterval(this.driveTestTimer);
        }
        
        this.driveTestTimer = setInterval(() => {
            this.driveTestSeconds--;
            this.updateTimerDisplay();
            
            if (this.driveTestSeconds <= 0) {
                this.endDriveTest();
            }
        }, 1000);
        
        this.sendRequest('startDriveTest', {});
    }
    
    endDriveTest() {
        if (this.driveTestTimer) {
            clearInterval(this.driveTestTimer);
            this.driveTestTimer = null;
        }
        
        const timerElement = document.getElementById('drive-test-timer');
        if (timerElement) {
            timerElement.classList.add('hidden');
        }
        
        this.sendRequest('endDriveTest', {});
    }
    
    updateTimerDisplay() {
        const minutes = Math.floor(this.driveTestSeconds / 60);
        const seconds = this.driveTestSeconds % 60;
        const timeString = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
        
        const timerDisplay = document.getElementById('timer-display');
        if (timerDisplay) {
            timerDisplay.textContent = timeString;
        }
    }
    
    showDriveTestTimer(duration) {
        if (this.isDebugMode) {
            console.log(`Showing drive test timer for ${duration} seconds`);
        }
        
        this.driveTestSeconds = duration;
        this.updateTimerDisplay();
        
        const timerElement = document.getElementById('drive-test-timer');
        if (timerElement) {
            timerElement.classList.remove('hidden');
        }
    }
    
    updateDriveTestTimer(remainingTime) {
        this.driveTestSeconds = remainingTime;
        this.updateTimerDisplay();
        
        if (this.isDebugMode) {
            console.log(`Timer updated: ${remainingTime} seconds remaining`);
        }
        
        // Cambiar color cuando queden pocos segundos
        const timerDisplay = document.getElementById('timer-display');
        if (timerDisplay) {
            if (remainingTime <= 10) {
                timerDisplay.classList.add('timer-warning');
            } else {
                timerDisplay.classList.remove('timer-warning');
            }
        }
    }
    
    hideDriveTestTimer() {
        if (this.isDebugMode) {
            console.log('Hiding drive test timer');
        }
        
        const timerElement = document.getElementById('drive-test-timer');
        if (timerElement) {
            timerElement.classList.add('hidden');
        }
        
        // Limpiar clase de warning si existe
        const timerDisplay = document.getElementById('timer-display');
        if (timerDisplay) {
            timerDisplay.classList.remove('timer-warning');
        }
        
        // Limpiar timer local si existe
        if (this.driveTestTimer) {
            clearInterval(this.driveTestTimer);
            this.driveTestTimer = null;
        }
    }
    
    sendRequest(endpoint, data = {}) {
        const resourceName = this.getParentResourceName();
        if (!resourceName) {
            if (this.isDebugMode) {
                console.error('Could not determine resource name');
            }
            return;
        }
        
        if (this.isDebugMode) {
            console.log(`Sending request to ${endpoint} with data:`, data);
        }
        
        fetch(`https://${resourceName}/${endpoint}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        }).then(response => {
            if (this.isDebugMode) {
                console.log(`Response from ${endpoint}:`, response.status);
            }
        }).catch(error => {
            if (this.isDebugMode) {
                console.error(`Error sending request to ${endpoint}:`, error);
            }
        });
    }
    
    setupButtonListeners() {
        const buttonHandlers = {
            'close-btn': () => this.closeUI(),
            'prev-btn': () => this.sendRequest('prevVehicle', {}),
            'next-btn': () => this.sendRequest('nextVehicle', {})
        };
        
        for (const [id, handler] of Object.entries(buttonHandlers)) {
            const button = document.getElementById(id);
            if (button) {
                button.addEventListener('click', handler);
                if (this.isDebugMode) {
                    console.log(`Button listener added for ${id}`);
                }
            } else {
                if (this.isDebugMode) {
                    console.warn(`Button with ID ${id} not found`);
                }
            }
        }
    }
    
    setupInputListeners() {
        const indexInput = document.getElementById('vehicle-index');
        if (indexInput) {
            indexInput.addEventListener('change', (e) => {
                const idx = parseInt(e.target.value);
                if (this.isValidIndex(idx)) {
                    this.sendRequest('setVehicleIndex', { index: idx });
                } else {
                    e.target.value = this.currentIndex;
                }
            });
        }
    }
    
    setupKeyboardListeners() {
        document.addEventListener('keydown', (event) => {
            if (!event.key) return;
            
            if (this.isDebugMode) {
                console.log(`Key pressed: ${event.key}`);
            }
            
            const keyHandlers = {
                'Escape': () => this.closeUI(),
                'ArrowLeft': () => {
                    event.preventDefault();
                    this.sendRequest('prevVehicle', {});
                },
                'ArrowRight': () => {
                    event.preventDefault();
                    this.sendRequest('nextVehicle', {});
                },
                'b': () => this.handleKey('B', () => this.sendCameraCommand('unlockCamera')),
                'B': () => this.handleKey('B', () => this.sendCameraCommand('unlockCamera')),
                'v': () => this.handleKey('V', () => this.sendCameraCommand('toggleView')),
                'V': () => this.handleKey('V', () => this.sendCameraCommand('toggleView')),
                'x': () => this.handleKey('X', () => this.sendCameraCommand('startDriveTest')),
                'X': () => this.handleKey('X', () => this.sendCameraCommand('startDriveTest'))
            };
            
            const handler = keyHandlers[event.key];
            if (handler) {
                if (this.isDebugMode) {
                    console.log(`Executing handler for key: ${event.key}`);
                }
                handler();
            }
        });
    }
    
    handleKey(key, action) {
        if (typeof action === 'function') {
            try {
                action();
            } catch (error) {
                if (this.isDebugMode) {
                    console.error(`Error handling key ${key}:`, error);
                }
            }
        }
    }
    
    isValidIndex(idx) {
        return !isNaN(idx) && idx >= 1 && idx <= this.totalVehicles;
    }
    
    getParentResourceName() {
        try {
            const hostname = window.location.hostname;
            if (hostname.startsWith('cfx-nui-')) {
                return hostname.replace('cfx-nui-', '');
            }
            return hostname;
        } catch (error) {
            if (this.isDebugMode) {
                console.error('Error getting resource name:', error);
            }
            return null;
        }
    }
}

let vehicleTesterUI;

document.addEventListener('DOMContentLoaded', () => {
    console.log('DOM loaded, initializing VehicleTesterUI...');
    vehicleTesterUI = new VehicleTesterUI();
    console.log('VehicleTesterUI initialized');
});

function GetParentResourceName() {
    return vehicleTesterUI ? vehicleTesterUI.getParentResourceName() : null;
}