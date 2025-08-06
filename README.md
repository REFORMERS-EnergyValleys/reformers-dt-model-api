# REFORMERS Digital Twin Model API & Container Regsitry

The REFORMERS Digital Twin Container Registry stores container images of model generators and models.
The REFORMERS Digital Twin Model API enables users / services to retrieve information about available model generators and models.

## Installation

1. Provide **server private key** (`server.key`) and **certificate** (`server.crt`) in sub-directory `certs`.
   For testing, you may use the following to generate private key and certificate, then check the details:
   ``` bash
   openssl genrsa -out certs/server.key 2048
   openssl req -new -x509 -sha256 -key certs/server.key -out certs/server.crt -config certs/certs.cfg -days 3650
   openssl x509 -in certs/server.crt -text -noout
   ```
2. Provide **authorization config file**:
   + Get your access credentials encoded in base64:
     ```
     echo -n admin:<REPO_ADMIN_PASSWORD> | base64
     ```
   + Create a JSON file with the following content, using the previously generated base64-encoded credentials:
     ```
     {
         "auths": {
             "<HOSTNAME>": {
                 "auth": "<BASE64-CREDENTIALS>"
             },
             "<HOSTNAME>:8082": {
                 "auth": "<BASE64-CREDENTIALS>"
             },
             "<HOSTNAME>:8083": {
                 "auth": "<BASE64-CREDENTIALS>"
             }
         }
     }
     ```
   For testing, you can use file [`auth-config.json.example`](./auth-config.json.example).
3. Define the following **environment variables**:
   + `HOSTNAME`: host name of the server (example: *reformers-dev.ait.ac.at*)
   + `REPO_ADMIN_PASSWORD`: administrator password
   + `AUTH_CONFIG_FULL_PATH`: full path to authorization config file
   For testing, you can use file [`.env.example`](./.env.example).
4. Start the service:
   ``` bash
   docker compose up -d
   ```

*NOTE*:
The instructions above create a self-signed certificate.
This will cause browsers and other software to complain about security risks.

## Usage

### Model API

The Model API is available at: `https://<HOSTNAME>/api`

A graphical user interface (Swagger UI) for the Model API is available at: `https://<HOSTNAME>/api/ui`

### Model generators - container images

#### Push

_ATTENTION_: Pushing an image requires a login first.

Container image registry for model generators (port 8082):
```
docker login <HOSTNAME>:8082
docker push <HOSTNAME>:8082/generator1:v1
```

#### Pull

Container image registry for model generators (port 8082):
```
docker pull <HOSTNAME>:8082/generator1:v1
```

### Models - container images

#### Push

_ATTENTION_: Pushing an image requires a login first.

Container image registry for models (port 8083):
```
docker login <HOSTNAME>:8083
docker push <HOSTNAME>:8083/generator1/v1/model1:latest
```

#### Pull

Container image registry for models (port 8083):
```
docker pull <HOSTNAME>:8083/generator1/v1/model1:latest
```

## Troubleshooting

### Login to Docker repositories fails

_Error message_: `tls: failed to verify certificate: x509: certificate signed by unknown authority`

_Solution_: Add the following to the Docker daemon configuration file (change `HOSTNAME` accordingly):
```json
"insecure-registries": [
  "https://<HOSTNAME>:8082",
  "https://<HOSTNAME>:8083"
]
```

## Known Issues

+ All access to the Sonatype Nexus3 repository (including the container image registries) is handled via the administrator account (user name `admin`).
