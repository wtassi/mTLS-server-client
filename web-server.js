const https = require('https');
const fs = require('fs');

const hostname = '127.0.0.1';
const port = 3000;

const options = {
    ca: fs.readFileSync('./certificates/certs/cacert.pem'),
    cert: fs.readFileSync('./certificates/server_certs/server.crt.pem'),
    key: fs.readFileSync('./certificates/server_certs/server.key.pem'),
    rejectUnauthorized: true,
    requestCert: true,
};

const server = https.createServer(options, (req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');
  res.end('\nServidor Respondeu.... \n    Hello World  :D \n');
});

server.listen(port, hostname, () => {
  console.log(`Server running at https://${hostname}:${port}/`);
});