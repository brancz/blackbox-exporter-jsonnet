{
  local blackboxExporter = self,

  name:: error 'must set namespace',
  namespace:: error 'must set namespace',
  version:: error 'must set version',
  image:: error 'must set image',

  config:: {
    modules: {
      http_2xx: {
        http: {
          no_follow_redirects: false,
          preferred_ip_protocol: 'ip4',
          valid_http_versions: ['HTTP/1.1', 'HTTP/2'],
          valid_status_codes: [],
        },
        prober: 'http',
        timeout: '5s',
      },
    },
  },

  commonLabels:: {
    'app.kubernetes.io/name': 'blackbox-exporter',
    'app.kubernetes.io/instance': blackboxExporter.name,
    'app.kubernetes.io/version': blackboxExporter.version,
  },

  podLabelSelector:: {
    [labelName]: blackboxExporter.commonLabels[labelName]
    for labelName in std.objectFields(blackboxExporter.commonLabels)
    if !std.setMember(labelName, ['app.kubernetes.io/version'])
  },

  configmap: {
    apiVersion: 'v1',
    kind: 'ConfigMap',
    metadata: {
      labels: blackboxExporter.commonLabels,
      name: blackboxExporter.name,
    },
    data: {
      'blackbox.yaml': std.manifestJsonEx(blackboxExporter.config, '  '),
    },
  },

  service: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      labels: blackboxExporter.commonLabels,
      name: blackboxExporter.name,
    },
    spec: {
      ports: [
        {
          name: 'http',
          port: 9115,
          protocol: 'TCP',
        },
      ],
      selector: blackboxExporter.podLabelSelector,
      type: 'ClusterIP',
    },
  },

  deployment: {
    apiVersion: 'apps/v1',
    kind: 'Deployment',
    metadata: {
      labels: blackboxExporter.commonLabels,
      name: blackboxExporter.name,
    },
    spec: {
      replicas: 1,
      selector: {
        matchLabels: blackboxExporter.podLabelSelector,
      },
      template: {
        metadata: {
          labels: blackboxExporter.commonLabels,
          annotations: {
            'checksum/config': std.md5(blackboxExporter.configmap.data['blackbox.yaml']),
          },
        },
        spec: {
          containers: [
            {
              args: [
                '--config.file=/config/blackbox.yaml',
              ],
              image: blackboxExporter.image,
              name: 'blackbox-exporter',
              ports: [
                {
                  containerPort: 9115,
                  name: 'http',
                },
              ],
              readinessProbe: {
                httpGet: {
                  path: '/health',
                  port: 'http',
                },
              },
              volumeMounts: [
                {
                  mountPath: '/config',
                  name: 'config',
                },
              ],
            },
          ],
          volumes: [
            {
              configMap: {
                name: blackboxExporter.configmap.metadata.name,
              },
              name: 'config',
            },
          ],
        },
      },
    },
  },
}
