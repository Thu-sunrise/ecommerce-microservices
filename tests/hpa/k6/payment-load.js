// k8s/hpa/tests/k6/payment-load.js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';
import { BASE_URL_PAYMENT, THRESHOLDS, RAMP_SCENARIO } from './config.js';

const errorRate = new Rate('payment_error_rate');
const latencyTrend = new Trend('payment_latency_ms', true);

export const options = {
    scenarios: {
        payment_hpa_test: RAMP_SCENARIO,
    },
    thresholds: THRESHOLDS,
};

export default function () {
    const url = BASE_URL_PAYMENT + '/actuator/health';
    const res = http.get(url, { timeout: '10s' });

    latencyTrend.add(res.timings.duration);
    errorRate.add(res.status >= 500);

    check(res, {
        'payment healthy': (r) => r.status === 200,
        'latency < 2000ms': (r) => r.timings.duration < 2000,
    });

    sleep(Math.random() * 0.4 + 0.1);
}
