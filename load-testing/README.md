First install locust, `python3 -m pip install locustio`

To run this script, you will need to export the token as an environment variable, i.e.

```
export access_token=...
```

You can then run the script like so:

```
locust -f mobile_api.py --no-web -c 20 -r 1 --host http://165.227.211.150:3000
```

Where c is the number of users, r is the hatch rate and the host is where the services are located.
This can also be run with the web gui and those values can be specified there, like so:

```
locust -f mobile_api.py --host http://165.227.211.150:3000
```
