class BuiltInSource {
  const BuiltInSource(this.group, this.label, this.url);

  final String group;
  final String label;
  final String url;
}

const builtInGroupName = '极光线路';
const builtInDefaultLine = '线路2';

const _staticSources = <BuiltInSource>[
  BuiltInSource(
    '线路2',
    'pawdroid',
    'https://raw.githubusercontent.com/Pawdroid/Free-servers/main/sub',
  ),
  BuiltInSource(
    '线路3',
    'shaoyou',
    'https://raw.githubusercontent.com/shaoyouvip/free/main/base64.txt',
  ),
  BuiltInSource(
    '线路4',
    'clashfree',
    'https://raw.githubusercontent.com/free-nodes/clashfree/main/sub.yml',
  ),
];

/// 内置订阅源。pawdroid/shaoyou 为固定 base64 地址，由 mihomo provider 自动
/// 转换并每日更新；clashfree 另外回退到最近几天带日期的文件，缺失的日期只会
/// 让该 provider 为空，不影响整份配置。
List<BuiltInSource> builtInSources([DateTime? now]) {
  final base = (now ?? DateTime.now()).toUtc().add(const Duration(hours: 8));
  final sources = <BuiltInSource>[..._staticSources];
  for (var back = 0; back < 4; back++) {
    final day = base.subtract(Duration(days: back));
    final y = day.year.toString().padLeft(4, '0');
    final m = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    sources.add(
      BuiltInSource(
        '线路4',
        'clashfree_$back',
        'https://raw.githubusercontent.com/free-nodes/clashfree/main/'
            'clash$y$m$d.yml',
      ),
    );
  }
  return sources;
}

/// 每条线路是独立的选择组，组内节点自动测速（url-test）；[builtInDefaultLine]
/// 为顶层默认选中的线路。provider 以 exclude-type 按类型剔除 ss 节点，比按名称
/// 的 exclude-filter 可靠。clashfree 的每日回退源并入 线路4。
String buildBuiltInProfile([DateTime? now]) {
  final sources = builtInSources(now);
  final buffer = StringBuffer()
    ..writeln('mixed-port: 7890')
    ..writeln('allow-lan: false')
    ..writeln('mode: rule')
    ..writeln('log-level: info')
    ..writeln('proxies: []')
    ..writeln('proxy-providers:');
  for (final source in sources) {
    buffer
      ..writeln('  ${source.label}:')
      ..writeln('    type: http')
      ..writeln('    url: ${source.url}')
      ..writeln('    path: ./providers/${source.label}.yaml')
      ..writeln('    interval: 86400')
      ..writeln('    exclude-type: ss');
  }
  final groups = <String, List<String>>{};
  for (final source in sources) {
    groups.putIfAbsent(source.group, () => <String>[]).add(source.label);
  }
  buffer
    ..writeln('proxy-groups:')
    ..writeln('  - name: $builtInGroupName')
    ..writeln('    type: select')
    ..writeln('    proxies:');
  for (final group in groups.keys) {
    buffer.writeln('      - $group');
  }
  buffer
    ..writeln('      - DIRECT')
    ..writeln('    default-selected: $builtInDefaultLine');
  for (final entry in groups.entries) {
    buffer
      ..writeln('  - name: ${entry.key}')
      ..writeln('    type: url-test')
      ..writeln('    use:');
    for (final label in entry.value) {
      buffer.writeln('      - $label');
    }
    buffer
      ..writeln('    url: https://www.gstatic.com/generate_204')
      ..writeln('    interval: 300')
      ..writeln('    lazy: false');
  }
  buffer
    ..writeln('rules:')
    ..writeln('  - GEOIP,CN,DIRECT')
    ..writeln('  - MATCH,$builtInGroupName');
  return buffer.toString();
}
