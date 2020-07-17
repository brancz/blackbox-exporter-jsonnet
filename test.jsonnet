local blackboxExporter = (import 'blackbox-exporter.libsonnet') {
  name: 'blackbox-exporter',
  namespace: 'test',
  version: 'v0.17.0',
  image: 'quay.io/prometheus/blackbox-exporter:' + blackboxExporter.version,
};

[
  blackboxExporter[name]
  for name in std.objectFields(blackboxExporter)
]
