#!/bin/bash
#-----------------------------------------------------------------------------------------#
# Gere alguns certificados de teste que são usados ​​pelo conjunto de testes de regressão:
#
#   ca.{crt,key}          Certificado CA autoassinado.
#   client.{crt,key}      Um certificado restrito para uso do cliente SSL.
#   server.{crt,key}      Um certificado restrito para uso do servidor SSL.
#-----------------------------------------------------------------------------------------#
# Variáveis Configuráveis de acordo com o desejável

# Configurações
APPLICATION="myapplication"
VALIDATE_CA_CERT=3650
VALIDATE_CRTS=365
DNS="app.meudomain.com.br"
DNS_SERVER="*.meudomain.com.br"
ORGANIZATION="WTassi S.A."
ENDERECO="Av. Rio Branco."
CIDADE="Juiz de Fora"
ESTADO="Minas Gerais"
PAIS_SIGLA="BR"
SERIALNUMBER="123456"
EMAIL="webmaster@meudomain.com.br"
CERT_PFX_PASS=""
# Nome Assunto para o CA Autoassinado.
ca_cert_cn="Devlop Local Certificate Authority"


#-----------------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------------#
# Primeiro, precisaríamos de um certificado CA que pudesse assinar os certificados do cliente e do servidor. Então, vamos criar nossa estrutura de diretórios para armazenar o certificado e a chave da CA.

# Caminho de saída dos arquivos gerados.
tlsPath="./certificates"
mkdir -p "$tlsPath" && chmod -R 777 "$tlsPath"
path_root="$tlsPath/"

mkdir -p "$path_root"
mkdir -p "$path_root/private" "$path_root/certs"

# Em seguida, crie um arquivo index.txt e serial para rastrear a lista de certificados assinados pelo certificado CA.
### Serial:
# Um arquivo SERIAL é usado para rastrear o último número de série que foi usado para emitir um certificado. É importante que nunca dois certificados sejam emitidos com o mesmo número de série da mesma CA. O OpenSSL é um pouco peculiar sobre como lida com esse arquivo. Ele espera que o valor esteja em hexadecimal e deve conter pelo menos dois dígitos, portanto, devemos preencher o valor acrescentando um zero a ele.
echo $SERIALNUMBER > $path_root/serial

### INDEX.TXT
# Em seguida, criaremos um arquivo index.txt que é um tipo de banco de dados que acompanha os certificados emitidos pela CA. Como nenhum certificado foi emitido neste momento e o OpenSSL exige que o arquivo exista, simplesmente criaremos um arquivo vazio.
touch $path_root/index.txt

### openssl.cnf para criar o Certificado raiz da CA:
# Referencia: https://www.golinuxcloud.com/openssl-create-certificate-chain-linux/#Step_4_Configure_opensslcnf_for_Root_CA_Certificate
cat > "$path_root/openssl.cnf" <<_END_
# Esta definição interrompe as seguintes linhas se as fixarem se HOME não estiver definido. 
#HOME                    = .
#RANDFILE                = $ENV::HOME/.rnd

# Extra OBJECT IDENTIFIER info:
#oid_file               = $ENV::HOME/.oid
oid_section             = new_oids

[ new_oids ]
# Políticas usadas pelos exemplos de TSA. 
tsa_policy1 = 1.2.3.4.1
tsa_policy2 = 1.2.3.4.5.6
tsa_policy3 = 1.2.3.4.5.7

####################################################################

[ ca ]
default_ca      = CA_default                    # Seção Padrão da CA
[ CA_default ]
dir             = $path_root                    # Onde tudo é mantido
certs           = $path_root/certs              # Onde os certificados emitidos é mantido
database        = $path_root/index.txt          # Arquivo de índice do Banco de dados
                                                # Vários certificados com mesmo assunto.
new_certs_dir   = $path_root/certs              # Local padrão para novos certificados
certificate     = $path_root/certs/cacert.pem   # Nome do Certificado de CA
serial          = $path_root/serial             # Número de Serie Atual
crlnumber       = $path_root/crlnumber          # Número do CRL Atual
                                                # deve ser comentado para deixar uma CRL V1
private_key     = $path_root/private/cakey.pem  # Chave Privada da CA (importante não ser compartilhada)

name_opt        = ca_default              # Opção de Nome do Assunto
cert_opt        = ca_default              # Opções do Certificado

default_days    = 365                     # Tempo padrão para expiração dos certificados criados.
default_crl_days= 30                      # Tem para a próxima CRL
default_md      = sha256                  # Usar a chave SHA-256 por padrão
preserve        = no                      # Mantém a ordenação de DN passada
policy          = policy_match

# chave especifica o nome de uma seção que será usada para a política padrão.
[ policy_match ] 
# policies
# match: significa que o campo com esse nome em uma solicitação de certificado deve corresponder ao mesmo campo no certificado da CA.
# supplied: significa que o pedido de certificado deve conter o campo.
# opcional: significa que o campo não é obrigatório na solicitação do certificado.
commonName              = supplied
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = optional
emailAddress            = optional

# para criar certificados de CA intermediários
[ policy_anything ] 
commonName              = supplied
emailAddress            = optional
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional

####################################################################
# Os valores na seção [ req ] são aplicados ao criar solicitações de assinatura de certificado (CSR) ou certificados. A x509_extensionschave especifica o nome de uma seção que contém as extensões que queremos incluir no certificado.
[ req ] 
default_bits            = 4096
default_md              = sha256
default_keyfile         = privkey.pem
distinguished_name      = req_distinguished_name
x509_extensions         = v3_ca
#string_mask             = nombstr
string_mask             = utf8only

# determina como o OpenSSL obtém as informações necessárias para preencher o nome distinto do certificado
[ req_distinguished_name ] 
countryName                     = Country Name (2 letter code)
countryName_default             = BR
countryName_min                 = 2
countryName_max                 = 2
stateOrProvinceName             = State or Province Name (full name)
stateOrProvinceName_default     = Minas Gerais
localityName                    = Locality Name (eg, city)
localityName_default            = Belo Horizonte
0.organizationName              = Organization Name (eg, company)
0.organizationName_default      = WTassi
organizationalUnitName          = Organizational Unit Name (eg, section)
commonName                      = Common Name (eg, your name or your server\'s hostname)
commonName_max                  = 64
emailAddress                    = Email Address
emailAddress_max                = 64

[ req_attributes ]
challengePassword               = A challenge password
challengePassword_min           = 4
challengePassword_max           = 20
unstructuredName                = An optional company name

[ v3_req ] 
# Extensões para adicionar a uma solicitação de certificado 
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment

[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical,CA:true

[ v3_intermediate_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ crl_ext ]
# issuerAltName=issuer:copy
authorityKeyIdentifier=keyid:always

_END_

#-----------------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------------#

# Cria o certificado de CA
[ -f "$path_root/private/cakey.pem" ] || openssl genrsa -out "$path_root/private/cakey.pem" 4096

# Cria o certificado de CA
openssl req \
  -x509 -new -sha256 \
  -days $VALIDATE_CA_CERT \
  -key "$path_root/private/cakey.pem" \
  -config "$path_root/openssl.cnf" \
  -subj "/CN=Self signed CA certificate./O=$ORGANIZATION/C=$PAIS_SIGLA/ST=$ESTADO" \
  -out "$path_root/certs/ca.crt"

# Converter certificado para formato PEM (Opcional)
openssl x509 -in "$path_root/certs/ca.crt" -out "$path_root/certs/cacert.pem" -outform PEM

#-----------------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------------#
# É importante que qualquer CSR que você gerar para certificados de cliente ou servidor, tenha o nome do país, estado e nome da organização correspondentes ao certificado da CA ou, ao assinar o certificado.

# Cria função que irá criar os certificados com uso do OpenSSL
generate_cert() {
  local name="$1"
  local cn="$2"
  local opts="$3"
  local path="$4"

  local keyfile="${path}/${name}.key.pem"
  local certfile="${path}/${name}.crt.pem"
  local csrfile="${path}/${name}.csr"
  local pfxfile="${path}/${name}.pfx"
  
  # Cria a chave privada
  [ -f "$keyfile" ] || openssl genrsa -out "$keyfile" 4096
  
  # Cria a solicitação de assinatura de certificado (CSR)
  openssl req \
    -new -sha256 \
    -subj "/CN=${cn}/O=$ORGANIZATION/C=$PAIS_SIGLA/ST=$ESTADO/L=$CIDADE/emailAddress=$EMAIL" \
    -out ${csrfile} \
    -key ${keyfile} 

  openssl ca \
    -config "$path_root/openssl.cnf" \
    ${opts} \
    -days $VALIDATE_CRTS \
    -notext \
    -batch \
    -in ${csrfile} \
    -out ${certfile}

  # openssl pkcs12 \
  #   -export \
  #   -out ${pfxfile} \
  #   -inkey ${keyfile} \
  #   -in ${certfile} \
  #   -certfile "$path_root/certs/ca.crt" \
  #   -passout pass:$CERT_PFX_PASS


  openssl pkcs12 -export \
    -in ${certfile} \
    -inkey ${keyfile} -passin pass:$CERT_PFX_PASS \
    -certfile "$path_root/certs/ca.crt" \
    -out ${pfxfile} \
    -passout pass:$CERT_PFX_PASS



}

#-----------------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------------#

### Cria Certificado de CLIENTE
mkdir -p "$path_root/client_certs"
cat > "$path_root/client_certs/client_ext.cnf" <<_END_
basicConstraints = CA:FALSE
nsCertType = client, email
nsComment = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection
_END_

## Executa Função....
generate_cert "client" "$DNS" "-extfile $path_root/client_certs/client_ext.cnf" "$path_root/client_certs"

#-----------------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------------#

### Cria Certificado de SERVIDOR
mkdir -p "$path_root/server_certs"
cat > "$path_root/server_certs/server_ext.cnf" <<_END_
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyAgreement, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[ alt_names ]
DNS.1 = $DNS_SERVER
DNS.2 = $DNS
DNS.3 = localhost
IP.1 = 127.0.0.1
_END_

## Executa Função....
generate_cert "server" "$DNS_SERVER" "-extfile $path_root/server_certs/server_ext.cnf" "$path_root/server_certs"

#-----------------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------------#
