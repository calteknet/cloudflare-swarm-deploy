const express = require('express');
const basicAuth = require('express-basic-auth');
const { exec } = require('child_process');
const app = express();
const http = require('http').createServer(app);
const io = require('socket.io')(http);

// Basic authentication
app.use(basicAuth({
    users: { 'admin': 'your-secure-password' },
    challenge: true
}));

// Serve static files
app.use(express.static('public'));

// Get system stats
const getSystemStats = async () => {
    const execPromise = cmd => new Promise((resolve, reject) => {
        exec(cmd, (error, stdout, stderr) => {
            if (error) reject(error);
            else resolve(stdout.trim());
        });
    });

    try {
        const disk = await execPromise("df -h / | awk 'NR==2 {print $5}'");
        const memory = await execPromise("free -m | awk 'NR==2 {print $3/$2*100}'");
        const dockerStats = await execPromise("docker stats --no-stream --format '{{.Name}},{{.CPUPerc}},{{.MemUsage}}'");

        return {
            disk,
            memory: parseFloat(memory).toFixed(2),
            containers: dockerStats.split('\n').map(line => {
                const [name, cpu, mem] = line.split(',');
                return { name, cpu, mem };
            })
        };
    } catch (error) {
        console.error('Error getting system stats:', error);
        return null;
    }
};

// Socket.io connection
io.on('connection', socket => {
    console.log('Client connected');
    
    // Send stats every 5 seconds
    const statsInterval = setInterval(async () => {
        const stats = await getSystemStats();
        if (stats) socket.emit('stats', stats);
    }, 5000);

    socket.on('disconnect', () => {
        clearInterval(statsInterval);
        console.log('Client disconnected');
    });
});

// Routes
app.get('/api/health', async (req, res) => {
    const stats = await getSystemStats();
    res.json(stats);
});

http.listen(3000, () => {
    console.log('Monitor dashboard running on port 3000');
});
