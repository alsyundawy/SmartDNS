<?php

/**
 * SmartDNS Telemetry Receiver API
 * Target: https://telemetry.alsyundawy.com/api/v1/heartbeat.php
 * Copyright (c) ALSYUNDAWY IT SOLUTION
 */

declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');

// 1. Method guard
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'status' => 'error',
        'message' => 'Method Not Allowed'
    ], JSON_UNESCAPED_SLASHES);
    exit;
}

// 2. Read and decode JSON payload
$raw_input = file_get_contents('php://input');
if ($raw_input === false || trim($raw_input) === '') {
    http_response_code(400);
    echo json_encode([
        'status' => 'error',
        'message' => 'Empty request body'
    ], JSON_UNESCAPED_SLASHES);
    exit;
}

$payload = json_decode($raw_input, true);
if (!is_array($payload) || json_last_error() !== JSON_ERROR_NONE) {
    http_response_code(400);
    echo json_encode([
        'status' => 'error',
        'message' => 'Invalid JSON payload format'
    ], JSON_UNESCAPED_SLASHES);
    exit;
}

// 3. Strict UUID format validation (prevent path traversal)
$uuid = $payload['uuid'] ?? '';
$uuid_pattern = '/^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/';
if (!is_string($uuid) || !preg_match($uuid_pattern, $uuid)) {
    http_response_code(400);
    echo json_encode([
        'status' => 'error',
        'message' => 'Invalid or missing telemetry UUID'
    ], JSON_UNESCAPED_SLASHES);
    exit;
}

// 4. Resolve real client IP address (Cloudflare / Reverse Proxy friendly)
$client_ip = $_SERVER['HTTP_CF_CONNECTING_IP']
    ?? $_SERVER['HTTP_X_FORWARDED_FOR']
    ?? $_SERVER['REMOTE_ADDR']
    ?? '0.0.0.0';

if (strpos($client_ip, ',') !== false) {
    $client_ip = trim(explode(',', $client_ip)[0]);
}

$clean_ip = filter_var($client_ip, FILTER_VALIDATE_IP) ? $client_ip : '0.0.0.0';

// 5. Append server verification metadata
$payload['server_meta'] = [
    'received_at' => date('Y-m-d H:i:s'),
    'timestamp'   => time(),
    'client_ip'   => $clean_ip,
    'user_agent'  => substr($_SERVER['HTTP_USER_AGENT'] ?? 'SmartDNS', 0, 120),
];

// 6. Ensure data directory exists
$data_dir = dirname(__DIR__, 2) . '/data/nodes';
if (!is_dir($data_dir) && !mkdir($data_dir, 0750, true) && !is_dir($data_dir)) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Internal storage directory unavailable'
    ], JSON_UNESCAPED_SLASHES);
    exit;
}

// 7. Atomic write per UUID
$target_file = $data_dir . '/' . strtolower($uuid) . '.json';
$encoded = json_encode($payload, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);

if ($encoded === false || file_put_contents($target_file, $encoded, LOCK_EX) === false) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Failed to persist telemetry payload'
    ], JSON_UNESCAPED_SLASHES);
    exit;
}

// 8. Return success response
http_response_code(200);
echo json_encode([
    'status'    => 'ok',
    'message'   => 'Heartbeat acknowledged',
    'uuid'      => strtolower($uuid),
    'timestamp' => time()
], JSON_UNESCAPED_SLASHES);
