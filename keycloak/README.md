# How to run it locally in a docker container

```
docker run -d --name mykeycloak -p 3001:8080 \
        -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=change_me \
        mykeycloak:theme \
        start-dev
```
