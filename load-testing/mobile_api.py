from locust import HttpLocust, TaskSet
import os
import resource


def trees(l):
   access_token = os.environ['access_token']
   headers = {"authorization": "Bearer %s" % access_token}
   l.client.get('/trees/details/user',headers=headers)

class UserBehavior(TaskSet):
    tasks = {trees: 2 }

class WebsiteUser(HttpLocust):
    resource.setrlimit(resource.RLIMIT_NOFILE, (999999, 999999))
    print(resource.getrlimit(resource.RLIMIT_NOFILE))
    task_set = UserBehavior
    min_wait = 200
    max_wait = 1000
