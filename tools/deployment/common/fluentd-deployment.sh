#!/bin/bash

#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

set -xe

#NOTE: Lint and package chart
make fluentd

: ${OSH_INFRA_EXTRA_HELM_ARGS_FLUENTD:="$(./tools/deployment/common/get-values-overrides.sh fluentd)"}

if [ ! -d "/var/log/journal" ]; then
tee /tmp/fluentd.yaml << EOF
deployment:
  type: Deployment
pod:
  replicas:
    fluentd: 1
  mounts:
    fluentbit:
      fluentbit:
        volumes:
          - name: runlog
            hostPath:
              path: /run/log
        volumeMounts:
          - name: runlog
            mountPath: /run/log
EOF
helm upgrade --install fluentd ./fluentd \
    --namespace=osh-infra \
    --values=/tmp/fluentd.yaml \
  ${OSH_INFRA_EXTRA_HELM_ARGS} \
  ${OSH_INFRA_EXTRA_HELM_ARGS_FLUENTD}

else
tee /tmp/fluentd.yaml << EOF
deployment:
  type: Deployment
pod:
  replicas:
    fluentd: 1
EOF
fi
helm upgrade --install fluentd ./fluentd \
    --namespace=osh-infra \
    --values=/tmp/fluentd.yaml \
  ${OSH_INFRA_EXTRA_HELM_ARGS} \
  ${OSH_INFRA_EXTRA_HELM_ARGS_FLUENTD}

#NOTE: Wait for deploy
./tools/deployment/common/wait-for-pods.sh osh-infra

#NOTE: Validate Deployment info
helm status fluentd
