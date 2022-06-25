# Server-Client-mTLS

A ideia deste repositório, é tentar, digo, TENTAR, diminuir tal complexidade na emissão de certificados e configuração dos mesmos assim como testar uma chamada a uma API passando os certificados necessários.

>OBS: no arquivo `gencerts.sh` possui valores DEFAULT, que tem de a servir como **EXEMPLO** para vocês. Além de explicações sobre cada propriedade (mais importantes) do `openssl`.

Para Rodar o Script BASH, recomendo executar de um terminal Linux.
Eu utilizo SO Windows, possuo o Docker-Desktop instalado, e consequentemente uma instancia WSL do Ubuntu, então quando abro o VSCODE (minha IDE de atuação), eu **Abro um terminal (CTRL+J), vou no cantinho inferior direito, clico no na setinha pra baixo ao lado de + e escolho a opção "Ubuntu (WSL)" e ZAZZZZ.... terminal Linux dentro do Windows... e tudo é lindo.
Para execução do Projeto em Node.js, executo no querido Powershell (integrado e default do VSCODE).

## > Install & Dependence
### **Windows**
| Software   | Download |
| ---       | ---      |
| Node | [download](https://nodejs.org/dist/v16.15.1/node-v16.15.1-x64.msi) |
| Docker-Desktop | [download](https://nodejs.org/dist/v16.15.1/node-v16.15.1-linux-x64.tar.xz) |

### **Linux**
| Software   | Download |
| ---       | ---      |
| Node | [download](https://nodejs.org/dist/v16.15.1/node-v16.15.1-linux-x64.tar.xz) |
| Docker-Desktop | [download](https://docs.docker.com/desktop/linux/install/) |

## Execução:

1. Abra o arquivo `gencerts.sh` presente na raiz deste projeto, e da linha **12** até a linha **25** são valores possíveis de alterações sem que haja problemas... dali para baixo, recomendo não mexer se não for a fim de aprendizado, alterações, curiosidades e etc... que é o intuito de fornecimento deste código.

2. Abra o terminal Linux e execute o comando que irá criar todos os certificados.
```bash
mTLS-server-client$   ./gencerts.sh
```

3. Executando server (in Node.js):
```powershell
PS E:\_git\mTLS-server-client>   npm install
PS E:\_git\mTLS-server-client>   node .\web-server.js 

# Irá aparecer uma saída como esta:
Server running at https://127.0.0.1:3000/
```

4. Executando uma chamada na API (via terminal LINUX com o uso do CURL) - SEM CERTIFICADO
```bash
mTLS-server-client$   curl https://127.0.0.1:3000/

# Uma saída como esta abaixo deverá acontecer....
curl: (60) SSL certificate problem: self signed certificate in certificate chain
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.

# Significa que a aplicação espera por um Certificado válido com base na combinação de Server-CERT e CA-CERT configurado durante o hand-shake do protocolo TLS.
```

5. Executando uma chamada na API (via terminal LINUX com o uso do CURL) - COM CERTIFICADO DE CLIENTE
```bash
mTLS-server-client$   curl --cacert "./certificates/certs/cacert.pem" \
  --key "./certificates/client_certs/client.key.pem" \
  --cert "./certificates/client_certs/client.crt.pem" \
  https://127.0.0.1:3000

# E uma saída como esta abaixo deverá aparecer:
Servidor Respondeu....
  Hello World  :D

# Significa que o cliente conseguiu acessar o servidor com um certificado valido
```

## Saída esperada do diretório:
```
|—— .gitignore
|—— aReadme.md
|—— certificates
|    |—— certs
|        |—— 123456.pem
|        |—— 123457.pem
|        |—— ca.crt
|        |—— cacert.pem
|    |—— client_certs
|        |—— client.crt.pem
|        |—— client.csr
|        |—— client.key.pem
|        |—— client_ext.cnf
|    |—— index.txt
|    |—— index.txt.attr
|    |—— index.txt.attr.old
|    |—— index.txt.old
|    |—— openssl.cnf
|    |—— private
|        |—— cakey.pem
|    |—— serial
|    |—— serial.old
|    |—— server_certs
|        |—— server.crt.pem
|        |—— server.csr
|        |—— server.key.pem
|        |—— server_ext.cnf
|—— gencerts.sh
|—— LICENSE
|—— node_modules
|    |—— .bin
|    |—— .package-lock.json
|—— package-lock.json
|—— package.json
|—— SECURITY.md
|—— Teste.png
|—— web-server.js
```

## Mutual TLS (mTLS)
A autenticação TLS mútua (mTLS) garante que o tráfego seja seguro e ambas as partes estejam fortemente autenticadas. Nas negociações de criptografia tradicional TLS, apenas o servidor se autentica usando chaves de criptografia, no entanto no mTLS ambas as partes (cliente e servidor) devem autenticar-se apresentando seus certificados e usando suas chaves privadas. A encriptação ocorre na camada de transporte durante o hand-shake do protocolo TLS.

Verifique que na figura 1, a troca inicial de mensagens é feita usando chaves assimétricas e após autenticação de ambas partes, é gerada uma chave simétrica e terminando a negociação.

[](./Prints/Documentação_01.png)
<img src="Prints/Documentação_01.png"/>

## Como utilizar o mTLS em seu projeto sem muita bagunça
O projeto mTLS Best Friend traz soluções bem úteis para quem deseja utilizar a tecnologia em seu projeto, o endereço do projeto é https://mtls.run/. O projeto traz formas rápidas de testar o lado do servidor ou cliente e uma arquitetura bem legal de webhook para colocar no seu projeto que estarei introduzindo em seguida, e caso queira saber mais detalhes pode acessar o página oficial.

## SideCar proxy
A idéia de utilizar um Sidecar Proxy em seu projeto vai permitir que você utilize o mTLS sem ter que lidar diretamente com mTLS em seu projeto. Conforme ilustrado na figura abaixo, a tua API se comunica através do protocolo HTTP com o mTLS sidecar proxy que por sua vez é o responsável por lidar com questões de certificados, chaves, permissões e com a conexão.

[](./Prints/Documentação_02.png)
<img src="Prints/Documentação_02.png"/>

Por outro lado, do lado do servidor teremos o ambassador que tem o mesmo objetivo do sidecar proxy, ou seja, lidar com a conexão mTLS sem ser necessário que cada um dos serviços implemente ela diretamente.

[](./Prints/Documentação_03.png)
<img src="Prints/Documentação_03.png"/>

Por fim, nossa arquitetura completa será como ilustra a figura abaixo. Tornando teu projeto ainda mais seguro.

[](./Prints/Documentação_04.png)
<img src="Prints/Documentação_04.png"/>

##### Fonte: https://rfsaraujobr.medium.com/mtls-de-uma-forma-amig%C3%A1vel-6506c84c1b7e
