from datetime import datetime
from typing import List

from kubernetes import client, config


def _format_print(name: str, namespace: str, latest_state_change_str: str, images: List[str]):
    print(f"{name[:40]:<40}\t{namespace:<25}\t{latest_state_change_str}\t{images}\t")


def main():
    try:
        config.load_kube_config()
    except:
        # load_kube_config throws if there is no config, but does not document what it throws, so I can't rely on any particular type here
        config.load_incluster_config()

    v1 = client.AppsV1Api()
    ret = v1.list_deployment_for_all_namespaces()
    images = 'Image List'
    name = 'Deployment Name'
    namespace = 'Namespace'
    latest_state_change_str = 'Latest state change'
    _format_print(name, namespace, latest_state_change_str, images)
    _format_print('-' * 40, '-' * 25, '-' * len('2022-03-09 00:53'), '-' * 40)
    for deployment in ret.items:
        images = [
            container.image for container in deployment.spec.template.spec.containers]
        latest_state_change: datetime = max(
            [condition.last_update_time for condition in deployment.status.conditions])
        name = deployment.metadata.name
        namespace = deployment.metadata.namespace
        latest_state_change_str = latest_state_change.strftime(
            "%Y-%m-%d %H:%M")
        _format_print(name, namespace, latest_state_change_str, images)


if __name__ == '__main__':
    main()
