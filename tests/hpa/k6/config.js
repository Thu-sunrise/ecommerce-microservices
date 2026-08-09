// k8s/hpa/tests/k6/config.js

export const BASE_URL_PRODUCT = __ENV.PRODUCT_URL || 'http://product-service.ecommerce.svc.cluster.local:8086';
export const BASE_URL_PAYMENT = __ENV.PAYMENT_URL || 'http://payment-service.ecommerce.svc.cluster.local:8085';

// Ngưỡng cho stress test — nới lỏng để không báo FAIL khi service đang chịu tải cao
export const THRESHOLDS = {
  http_req_failed:   ['rate<0.30'],     // chấp nhận tối đa 30% lỗi khi stress
  http_req_duration: ['p(95)<10000'],   // p95 < 10s khi overload
  http_reqs:         ['rate>5'],         // throughput tối thiểu 5 req/s
};

// Kịch bản tải: Ramp Up → Stress → Ramp Down
export const RAMP_SCENARIO = {
    executor: 'ramping-vus',
    startVUs: 0,
    stages: [
        { duration: '2m', target: 50  }, // Warm-up: 0→50 VU
        { duration: '3m', target: 150 }, // Ramp-up: 50→150 VU (bắt đầu gây CPU load)
        { duration: '3m', target: 200 }, // Stress: giữ 200 VU, nhắm CPU > 70%
        { duration: '2m', target: 100 }, // Ramp-down: 200→100 VU
        { duration: '2m', target: 0   }, // Cool-down: quan sát HPA scale-down
    ],
};
