// Performance Monitor for ROHTML
// This script tracks input latency and performance metrics

class PerformanceMonitor {
    constructor() {
        this.inputLatency = [];
        this.frameTimes = [];
        this.lastFrameTime = performance.now();
        this.inputCount = 0;
        this.lastInputTime = 0;
        
        this.setupMonitoring();
    }

    setupMonitoring() {
        // Monitor frame times
        const measureFrameTime = () => {
            const now = performance.now();
            const frameTime = now - this.lastFrameTime;
            this.frameTimes.push(frameTime);
            
            // Keep only last 100 measurements
            if (this.frameTimes.length > 100) {
                this.frameTimes.shift();
            }
            
            this.lastFrameTime = now;
            requestAnimationFrame(measureFrameTime);
        };
        
        requestAnimationFrame(measureFrameTime);

        // Monitor input latency
        const originalHandleAhkInput = window.handleAhkInput;
        window.handleAhkInput = (dataString) => {
            const startTime = performance.now();
            
            // Call original function
            originalHandleAhkInput(dataString);
            
            // Measure latency
            const latency = performance.now() - startTime;
            this.inputLatency.push(latency);
            this.inputCount++;
            
            // Keep only last 100 measurements
            if (this.inputLatency.length > 100) {
                this.inputLatency.shift();
            }
            
            this.lastInputTime = startTime;
        };

        // Display stats every 5 seconds
        setInterval(() => {
            this.displayStats();
        }, 5000);
    }

    displayStats() {
        if (this.inputLatency.length === 0) return;

        const avgLatency = this.inputLatency.reduce((a, b) => a + b, 0) / this.inputLatency.length;
        const maxLatency = Math.max(...this.inputLatency);
        const minLatency = Math.min(...this.inputLatency);
        
        const avgFrameTime = this.frameTimes.reduce((a, b) => a + b, 0) / this.frameTimes.length;
        const fps = 1000 / avgFrameTime;

        console.log(`=== ROHTML Performance Stats ===`);
        console.log(`Input Latency: ${avgLatency.toFixed(2)}ms avg (${minLatency.toFixed(2)}ms min, ${maxLatency.toFixed(2)}ms max)`);
        console.log(`Frame Rate: ${fps.toFixed(1)} FPS`);
        console.log(`Total Inputs: ${this.inputCount}`);
        console.log(`===============================`);
    }

    getStats() {
        if (this.inputLatency.length === 0) return null;

        const avgLatency = this.inputLatency.reduce((a, b) => a + b, 0) / this.inputLatency.length;
        const avgFrameTime = this.frameTimes.reduce((a, b) => a + b, 0) / this.frameTimes.length;
        const fps = 1000 / avgFrameTime;

        return {
            avgLatency: avgLatency.toFixed(2),
            maxLatency: Math.max(...this.inputLatency).toFixed(2),
            minLatency: Math.min(...this.inputLatency).toFixed(2),
            fps: fps.toFixed(1),
            inputCount: this.inputCount
        };
    }
}

// Initialize performance monitor when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.performanceMonitor = new PerformanceMonitor();
    
    // Add keyboard shortcut to show stats (Ctrl+Shift+P)
    document.addEventListener('keydown', (e) => {
        if (e.ctrlKey && e.shiftKey && e.key === 'P') {
            const stats = window.performanceMonitor.getStats();
            if (stats) {
                alert(`ROHTML Performance Stats:\n\n` +
                      `Input Latency: ${stats.avgLatency}ms avg\n` +
                      `Latency Range: ${stats.minLatency}ms - ${stats.maxLatency}ms\n` +
                      `Frame Rate: ${stats.fps} FPS\n` +
                      `Total Inputs: ${stats.inputCount}`);
            }
        }
    });
}); 