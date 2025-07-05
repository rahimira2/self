// Telegram Music Bot Panel - JavaScript
class MusicBotPanel {
    constructor() {
        this.currentChat = null;
        this.isConnected = false;
        this.currentTrack = null;
        this.queue = [];
        this.volume = 50;
        this.isPlaying = false;
        
        this.init();
    }

    init() {
        this.initEventListeners();
        this.initWebSocket();
        this.updateUI();
        this.getChatFromURL();
    }

    getChatFromURL() {
        const urlParams = new URLSearchParams(window.location.search);
        this.currentChat = urlParams.get('chat');
        this.token = urlParams.get('token');
        
        if (this.currentChat && this.token) {
            this.connectToBot();
        }
    }

    initEventListeners() {
        // Play/Pause button
        document.getElementById('playPauseBtn').addEventListener('click', () => {
            this.togglePlayPause();
        });

        // Next/Previous buttons
        document.getElementById('nextBtn').addEventListener('click', () => {
            this.sendCommand('skip');
        });

        document.getElementById('prevBtn').addEventListener('click', () => {
            this.sendCommand('previous');
        });

        // Shuffle and repeat
        document.getElementById('shuffleBtn').addEventListener('click', () => {
            this.sendCommand('shuffle');
        });

        document.getElementById('repeatBtn').addEventListener('click', () => {
            this.sendCommand('repeat');
        });

        // Add music button
        document.getElementById('addBtn').addEventListener('click', () => {
            this.addMusic();
        });

        // Music input enter key
        document.getElementById('musicInput').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                this.addMusic();
            }
        });

        // Volume slider
        document.getElementById('volumeSlider').addEventListener('input', (e) => {
            this.setVolume(e.target.value);
        });

        // Queue actions
        document.getElementById('clearQueueBtn').addEventListener('click', () => {
            this.sendCommand('clear');
        });

        document.getElementById('shuffleQueueBtn').addEventListener('click', () => {
            this.sendCommand('shuffle');
        });

        // Auto-refresh every 5 seconds
        setInterval(() => {
            if (this.isConnected) {
                this.refreshData();
            }
        }, 5000);
    }

    initWebSocket() {
        // In a real implementation, you would connect to a WebSocket server
        // For this demo, we'll simulate the connection
        setTimeout(() => {
            this.setConnectionStatus(true);
            this.simulateData();
        }, 2000);
    }

    connectToBot() {
        this.showLoading(true);
        
        // Simulate API call to connect to bot
        setTimeout(() => {
            this.setConnectionStatus(true);
            this.showLoading(false);
            this.showToast('اتصال برقرار شد!', 'success');
            this.loadInitialData();
        }, 2000);
    }

    setConnectionStatus(connected) {
        this.isConnected = connected;
        const statusElement = document.getElementById('connectionStatus');
        const indicator = statusElement.querySelector('.status-indicator');
        const text = statusElement.querySelector('span');
        
        if (connected) {
            indicator.classList.remove('offline');
            indicator.classList.add('online');
            text.textContent = 'آنلاین';
        } else {
            indicator.classList.remove('online');
            indicator.classList.add('offline');
            text.textContent = 'آفلاین';
        }
    }

    loadInitialData() {
        // Load current playing track
        this.updateCurrentTrack({
            title: 'موزیک نمونه',
            artist: 'هنرمند نمونه',
            duration: 240,
            currentTime: 45,
            image: 'https://via.placeholder.com/80x80/667eea/ffffff?text=🎵'
        });

        // Load queue
        this.updateQueue([
            { id: 1, title: 'آهنگ اول', artist: 'هنرمند اول', duration: 180 },
            { id: 2, title: 'آهنگ دوم', artist: 'هنرمند دوم', duration: 220 },
            { id: 3, title: 'آهنگ سوم', artist: 'هنرمند سوم', duration: 195 }
        ]);

        // Update stats
        this.updateStats({
            totalTracks: 3,
            totalDuration: 595,
            connectedUsers: 12,
            playedToday: 28
        });
    }

    simulateData() {
        // Simulate some initial data for demo
        this.loadInitialData();
    }

    togglePlayPause() {
        this.isPlaying = !this.isPlaying;
        const btn = document.getElementById('playPauseBtn');
        const icon = btn.querySelector('i');
        
        if (this.isPlaying) {
            icon.className = 'fas fa-pause';
            this.sendCommand('resume');
        } else {
            icon.className = 'fas fa-play';
            this.sendCommand('pause');
        }
    }

    addMusic() {
        const input = document.getElementById('musicInput');
        const query = input.value.trim();
        
        if (!query) {
            this.showToast('لطفاً لینک یا نام آهنگ را وارد کنید', 'warning');
            return;
        }

        this.showLoading(true);
        
        // Simulate adding music
        setTimeout(() => {
            this.sendCommand('play', query);
            input.value = '';
            this.showLoading(false);
            this.showToast('آهنگ به صف اضافه شد!', 'success');
        }, 2000);
    }

    quickSearch(query) {
        document.getElementById('musicInput').value = query;
        this.addMusic();
    }

    setVolume(value) {
        this.volume = value;
        document.getElementById('volumeValue').textContent = value + '%';
        this.sendCommand('volume', value);
    }

    sendCommand(command, data = null) {
        if (!this.isConnected) {
            this.showToast('اتصال برقرار نیست', 'error');
            return;
        }

        console.log(`Sending command: ${command}`, data);
        
        // In a real implementation, you would send this to the bot API
        // For demo purposes, we'll just log it
        
        switch (command) {
            case 'skip':
                this.showToast('آهنگ رد شد', 'success');
                break;
            case 'pause':
                this.showToast('پخش متوقف شد', 'success');
                break;
            case 'resume':
                this.showToast('پخش ادامه یافت', 'success');
                break;
            case 'shuffle':
                this.showToast('صف بهم زده شد', 'success');
                break;
            case 'clear':
                this.clearQueue();
                this.showToast('صف پاک شد', 'success');
                break;
        }
    }

    updateCurrentTrack(track) {
        this.currentTrack = track;
        
        document.getElementById('trackTitle').textContent = track.title;
        document.getElementById('trackArtist').textContent = track.artist;
        document.getElementById('trackImage').src = track.image;
        document.getElementById('currentTime').textContent = this.formatTime(track.currentTime);
        document.getElementById('totalTime').textContent = this.formatTime(track.duration);
        
        const progress = (track.currentTime / track.duration) * 100;
        document.getElementById('progress').style.width = progress + '%';
    }

    updateQueue(queue) {
        this.queue = queue;
        const queueList = document.getElementById('queueList');
        
        if (queue.length === 0) {
            queueList.innerHTML = '<p style="text-align: center; color: var(--text-secondary); padding: 20px;">صف پخش خالی است</p>';
            return;
        }
        
        queueList.innerHTML = queue.map((track, index) => `
            <div class="queue-item" data-id="${track.id}">
                <div class="track-number">${index + 1}</div>
                <div class="track-info">
                    <div class="track-title">${track.title}</div>
                    <div class="track-duration">${this.formatTime(track.duration)}</div>
                </div>
                <button class="action-btn" onclick="musicBot.removeFromQueue(${track.id})">
                    <i class="fas fa-times"></i>
                </button>
            </div>
        `).join('');
    }

    clearQueue() {
        this.updateQueue([]);
        this.updateStats({
            totalTracks: 0,
            totalDuration: 0,
            connectedUsers: this.stats?.connectedUsers || 0,
            playedToday: this.stats?.playedToday || 0
        });
    }

    removeFromQueue(trackId) {
        this.queue = this.queue.filter(track => track.id !== trackId);
        this.updateQueue(this.queue);
        this.showToast('آهنگ از صف حذف شد', 'success');
    }

    updateStats(stats) {
        this.stats = stats;
        document.getElementById('totalTracks').textContent = stats.totalTracks;
        document.getElementById('totalDuration').textContent = this.formatTime(stats.totalDuration);
        document.getElementById('connectedUsers').textContent = stats.connectedUsers;
        document.getElementById('playedToday').textContent = stats.playedToday;
    }

    refreshData() {
        // Simulate refreshing data from server
        if (this.currentTrack && this.isPlaying) {
            this.currentTrack.currentTime += 5;
            if (this.currentTrack.currentTime >= this.currentTrack.duration) {
                this.currentTrack.currentTime = 0;
                // Simulate next track
                this.togglePlayPause();
            }
            this.updateCurrentTrack(this.currentTrack);
        }
    }

    formatTime(seconds) {
        const minutes = Math.floor(seconds / 60);
        const remainingSeconds = seconds % 60;
        return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
    }

    showLoading(show) {
        const overlay = document.getElementById('loadingOverlay');
        if (show) {
            overlay.classList.add('show');
        } else {
            overlay.classList.remove('show');
        }
    }

    showToast(message, type = 'success') {
        const container = document.getElementById('toastContainer');
        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        toast.innerHTML = `
            <div style="display: flex; align-items: center; gap: 10px;">
                <i class="fas fa-${this.getToastIcon(type)}"></i>
                <span>${message}</span>
            </div>
        `;
        
        container.appendChild(toast);
        
        // Remove toast after 3 seconds
        setTimeout(() => {
            toast.style.animation = 'toastSlideOut 0.3s ease forwards';
            setTimeout(() => {
                container.removeChild(toast);
            }, 300);
        }, 3000);
    }

    getToastIcon(type) {
        const icons = {
            success: 'check-circle',
            error: 'exclamation-circle',
            warning: 'exclamation-triangle',
            info: 'info-circle'
        };
        return icons[type] || 'info-circle';
    }

    updateUI() {
        // Update volume slider
        document.getElementById('volumeSlider').value = this.volume;
        document.getElementById('volumeValue').textContent = this.volume + '%';
    }
}

// Modal functions
function closeModal(modalId) {
    document.getElementById(modalId).classList.remove('show');
}

function openModal(modalId) {
    document.getElementById(modalId).classList.add('show');
}

// Quick search function
function quickSearch(query) {
    musicBot.quickSearch(query);
}

// Initialize the application
const musicBot = new MusicBotPanel();

// Add CSS animation for toast slide out
const style = document.createElement('style');
style.textContent = `
    @keyframes toastSlideOut {
        to {
            opacity: 0;
            transform: translateX(100%);
        }
    }
`;
document.head.appendChild(style);

// Add keyboard shortcuts
document.addEventListener('keydown', (e) => {
    if (e.target.tagName === 'INPUT') return;
    
    switch (e.key) {
        case ' ':
            e.preventDefault();
            musicBot.togglePlayPause();
            break;
        case 'ArrowRight':
            e.preventDefault();
            musicBot.sendCommand('skip');
            break;
        case 'ArrowLeft':
            e.preventDefault();
            musicBot.sendCommand('previous');
            break;
        case 'ArrowUp':
            e.preventDefault();
            const currentVolume = parseInt(document.getElementById('volumeSlider').value);
            musicBot.setVolume(Math.min(100, currentVolume + 5));
            break;
        case 'ArrowDown':
            e.preventDefault();
            const currentVol = parseInt(document.getElementById('volumeSlider').value);
            musicBot.setVolume(Math.max(0, currentVol - 5));
            break;
    }
});

// Add click outside modal to close
document.addEventListener('click', (e) => {
    if (e.target.classList.contains('modal')) {
        e.target.classList.remove('show');
    }
});

console.log('🎵 ربات موزیک تلگرام آماده است!');