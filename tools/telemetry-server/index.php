<?php

/**
 * SmartDNS Fleet Monitoring Dashboard
 * Domain: alsyundawy.com
 * Copyright (c) ALSYUNDAWY IT SOLUTION
 */

declare(strict_types=1);

// Optional simple security key protection: ?key=YOUR_SECRET
$dashboard_secret = getenv('SMARTDNS_DASHBOARD_SECRET') ?: 'alsyundawy2026';
$provided_key = $_GET['key'] ?? '';

if ($dashboard_secret !== '' && $provided_key !== $dashboard_secret) {
    http_response_code(403);
    $access_msg = '<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">'
        . '<title>403 Forbidden</title></head>'
        . '<body style="background:#0f172a;color:#f8fafc;font-family:sans-serif;padding:40px;text-align:center;">'
        . '<h2>🔒 Access Restricted</h2>'
        . '<p>Tambahkan parameter <code>?key=alsyundawy2026</code> pada URL untuk mengakses dashboard fleet.</p>'
        . '</body></html>';
    echo $access_msg;
    exit;
}

$nodes_dir = __DIR__ . '/data/nodes';
$nodes = [];

if (is_dir($nodes_dir)) {
    $files = glob($nodes_dir . '/*.json') ?: [];
    foreach ($files as $file) {
        $raw = file_get_contents($file);
        if ($raw === false) {
            continue;
        }
        $node = json_decode($raw, true);
        if (!is_array($node)) {
            continue;
        }

        $last_ts = (int) ($node['server_meta']['timestamp'] ?? 0);
        $diff = time() - $last_ts;
        $is_online = ($diff <= 600); // 10 minutes heartbeat threshold

        $nodes[] = [
            'uuid'       => $node['uuid'] ?? 'N/A',
            'hostname'   => $node['system']['hostname'] ?? 'Unknown Node',
            'ip'         => $node['network']['ipv4'] ?? $node['server_meta']['client_ip'] ?? '0.0.0.0',
            'version'    => $node['version'] ?? 'unknown',
            'os'         => ($node['system']['os'] ?? '') . ' ' . ($node['system']['version'] ?? ''),
            'arch'       => $node['system']['arch'] ?? '',
            'cpu'        => ($node['system']['cpu_model'] ?? '') . ' (' . ($node['system']['cpu_threads'] ?? 0) . 'T)',
            'ram'        => (int) ($node['system']['memory_mb'] ?? 0),
            'uptime'     => $node['system']['uptime'] ?? 'Unknown',
            'dnssec'     => !empty($node['features']['dnssec']),
            'ratelimit'  => !empty($node['features']['ratelimit']),
            'last_seen'  => $node['server_meta']['received_at'] ?? 'N/A',
            'diff_sec'   => $diff,
            'is_online'  => $is_online,
        ];
    }
}

// Sort by online status first, then hostname
usort($nodes, static function ($a, $b) {
    if ($a['is_online'] === $b['is_online']) {
        return strcmp($a['hostname'], $b['hostname']);
    }
    return $a['is_online'] ? -1 : 1;
});

$online_nodes = array_filter($nodes, static fn($n) => $n['is_online']);
$online_count = count($online_nodes);
?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SmartDNS Fleet Monitor — ALSYUNDAWY IT SOLUTION</title>
    <style>
        :root {
            --bg: #090d16;
            --card-bg: #111827;
            --border: #1f2937;
            --text: #f9fafb;
            --muted: #9ca3af;
            --primary: #38bdf8;
            --success: #10b981;
            --danger: #ef4444;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            background-color: var(--bg);
            color: var(--text);
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            padding: 30px;
            line-height: 1.5;
        }
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 25px;
            padding-bottom: 20px;
            border-bottom: 1px solid var(--border);
        }
        .title h1 {
            font-size: 1.5rem;
            color: var(--text);
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .title p { color: var(--muted); font-size: 0.9rem; }
        .stats {
            display: flex;
            gap: 15px;
        }
        .stat-card {
            background: var(--card-bg);
            border: 1px solid var(--border);
            padding: 10px 18px;
            border-radius: 8px;
            font-size: 0.85rem;
        }
        .stat-card strong {
            display: block;
            font-size: 1.25rem;
            color: var(--primary);
        }
        table {
            width: 100%;
            border-collapse: collapse;
            background: var(--card-bg);
            border: 1px solid var(--border);
            border-radius: 8px;
            overflow: hidden;
            font-size: 0.9rem;
        }
        th, td {
            padding: 12px 16px;
            text-align: left;
            border-bottom: 1px solid var(--border);
        }
        th {
            background: #1e293b;
            color: var(--muted);
            font-size: 0.75rem;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }
        tr:hover { background: rgba(255, 255, 255, 0.02); }
        .badge {
            display: inline-block;
            padding: 2px 8px;
            border-radius: 4px;
            font-size: 0.75rem;
            font-family: monospace;
            background: #1f2937;
            color: #e5e7eb;
        }
        .status-dot {
            display: inline-block;
            width: 8px;
            height: 8px;
            border-radius: 50%;
            margin-right: 6px;
        }
        .online { color: var(--success); font-weight: 600; }
        .online .status-dot { background: var(--success); box-shadow: 0 0 6px var(--success); }
        .offline { color: var(--danger); font-weight: 600; }
        .offline .status-dot { background: var(--danger); }
        .features { display: flex; gap: 4px; }
        .feat-tag { font-size: 0.7rem; padding: 1px 5px; border-radius: 3px; background: #374151; color: #d1d5db; }
        .footer {
            margin-top: 30px;
            font-size: 0.8rem;
            color: var(--muted);
            text-align: center;
        }
        .footer a { color: var(--primary); text-decoration: none; }
    </style>
</head>
<body>
    <div class="header">
        <div class="title">
            <h1>🛡️ SmartDNS Fleet Monitor</h1>
            <p>
                Sistem Pemantauan Node DNS Terpusat —
                <a href="https://alsyundawy.com" style="color:var(--primary);text-decoration:none;">alsyundawy.com</a>
            </p>
        </div>
        <div class="stats">
            <div class="stat-card">
                Total Node
                <strong><?= count($nodes); ?></strong>
            </div>
            <div class="stat-card">
                Online (≤10m)
                <strong style="color:var(--success);"><?= $online_count; ?></strong>
            </div>
        </div>
    </div>

    <?php if (empty($nodes)) : ?>
        <div style="background:var(--card-bg);border:1px solid var(--border);padding:40px;text-align:center;">
            <h3 style="color:var(--muted);">Belum ada data node yang masuk</h3>
            <p style="margin-top:8px;color:var(--muted);">
                Pastikan node SmartDNS telah menjalankan cron <code>smartdns-heartbeat</code> ke endpoint ini.
            </p>
        </div>
    <?php else : ?>
        <table>
            <thead>
                <tr>
                    <th>Status</th>
                    <th>Hostname</th>
                    <th>IP Publik</th>
                    <th>OS & Kernel</th>
                    <th>Versi SmartDNS</th>
                    <th>Hardware</th>
                    <th>Fitur</th>
                    <th>Uptime</th>
                    <th>Heartbeat Terakhir</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($nodes as $node) : ?>
                <tr>
                    <td>
                        <span class="<?= $node['is_online'] ? 'online' : 'offline'; ?>">
                            <span class="status-dot"></span><?= $node['is_online'] ? 'ONLINE' : 'OFFLINE'; ?>
                        </span>
                    </td>
                    <td><strong><?= htmlspecialchars($node['hostname'], ENT_QUOTES); ?></strong></td>
                    <td><span class="badge"><?= htmlspecialchars($node['ip'], ENT_QUOTES); ?></span></td>
                    <td>
                        <?= htmlspecialchars($node['os'], ENT_QUOTES); ?>
                        (<?= htmlspecialchars($node['arch'], ENT_QUOTES); ?>)
                    </td>
                    <td>
                        <span class="badge" style="color:var(--primary);">
                            <?= htmlspecialchars($node['version'], ENT_QUOTES); ?>
                        </span>
                    </td>
                    <td>
                        <?= (int) ($node['ram'] / 1024); ?> GB RAM /
                        <?= htmlspecialchars($node['cpu'], ENT_QUOTES); ?>
                    </td>
                    <td>
                        <div class="features">
                            <?php if ($node['dnssec']) : ?>
                                <span class="feat-tag">DNSSEC</span>
                            <?php endif; ?>
                            <?php if ($node['ratelimit']) : ?>
                                <span class="feat-tag">RATE-LIMIT</span>
                            <?php endif; ?>
                        </div>
                    </td>
                    <td><?= htmlspecialchars($node['uptime'], ENT_QUOTES); ?></td>
                    <td>
                        <span style="font-size:0.8rem;color:var(--muted);">
                            <?= htmlspecialchars($node['last_seen'], ENT_QUOTES); ?>
                        </span>
                    </td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    <?php endif; ?>

    <div class="footer">
        SmartDNS Telemetry Server &copy; <?= date('Y'); ?>
        <a href="https://alsyundawy.com" target="_blank">ALSYUNDAWY IT SOLUTION</a>.
    </div>
</body>
</html>
