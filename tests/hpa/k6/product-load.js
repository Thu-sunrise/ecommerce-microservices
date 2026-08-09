// k8s/hpa/tests/k6/product-load.js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';
import { BASE_URL_PRODUCT, THRESHOLDS, RAMP_SCENARIO } from './config.js';

// Custom metrics
const errorRate = new Rate('product_error_rate');
const latencyTrend = new Trend('product_latency_ms', true);

export const options = {
    scenarios: {
        product_hpa_test: RAMP_SCENARIO,
    },
    thresholds: THRESHOLDS,
};

// Danh sách endpoint PUBLIC (không cần auth) với context-path /product
// Xác nhận từ SecurityConfig: GET /api/products/**, /api/categories/** → permitAll()
const ENDPOINTS = [
    '/product/api/products?page=0&size=20',   // DB query + JSON serialize → tốn CPU
    '/product/api/products?page=1&size=50',   // page lớn hơn → nặng hơn
    '/product/api/categories',                // nhẹ hơn, ổn định
    '/product/v3/api-docs',                   // Swagger parse → tốn CPU vừa
];

export default function () {
    const url = BASE_URL_PRODUCT + ENDPOINTS[Math.floor(Math.random() * ENDPOINTS.length)];
    const params = {
        headers: { 'Content-Type': 'application/json' },
        timeout: '10s',
    };

    const res = http.get(url, params);

    // Ghi metrics
    latencyTrend.add(res.timings.duration);
    errorRate.add(res.status >= 500);

    // Kiểm tra response
    check(res, {
        'status 2xx': (r) => r.status >= 200 && r.status < 300,
        'latency < 2000ms': (r) => r.timings.duration < 2000,
        'not server error': (r) => r.status < 500,
    });

    // Sleep ngắn để không flood hoàn toàn nhưng vẫn đủ tải
    sleep(Math.random() * 0.1 + 0.05); // 50–150ms
}

export function handleSummary(data) {
    console.log('=== Product HPA Test Summary ===');
    console.log(`Total requests: ${data.metrics.http_reqs.values.count}`);
    console.log(`Error rate: ${(data.metrics.http_req_failed.values.rate * 100).toFixed(2)}%`);
    console.log(`p95 latency: ${data.metrics.http_req_duration.values['p(95)'].toFixed(0)}ms`);
    return {};
}
