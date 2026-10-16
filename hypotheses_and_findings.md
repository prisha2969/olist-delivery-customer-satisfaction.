# Hypotheses, Findings and Recommendations

## Bottom line

Delivery reliability is the biggest lever on customer satisfaction, but it is
necessary rather than sufficient. Late orders average **2.27 / 5** vs about **4.29**
for early ones. Yet only 6.8% of orders are late, so removing *every* late delivery
would raise the platform average review by only about 0.14 points (roughly 4.08 to
4.22). Freight cost barely matters, and repeat purchase (3.0%) is not explained by
first-order experience. The priorities are: fix the first week of delay, target the
Northeast and Rio de Janeiro, act on a short list of sellers, and treat several
categories as product problems rather than logistics problems.

## Analysis framework

| Layer | Question | Metrics |
|---|---|---|
| Customer | Who buys? | unique customers, first-time vs repeat, orders per customer, geography |
| Seller and product | Who/what drives the experience? | seller and category performance, revenue, order volume, freight |
| Experience | What happened during the transaction? | lead time, delay, early/on-time/late, review score, freight burden |
| Repeat purchase | Did the customer come back? | repeat rate, first-order experience vs repeat behaviour |

## Hypotheses and verdicts

| # | Hypothesis | Verdict | Evidence |
|---|-----------|---------|----------|
| H1 | Late deliveries are associated with lower review scores | **Strongly supported** | 2.27 (late) vs 4.29 (early); steep drop by days late (Q4, Q5) |
| H2 | Lower first-order review scores are associated with lower repeat purchase | **Not supported** | First review 4.20 (repeat) vs 4.15 (one-time) (Q8) |
| H3 | Higher freight burden is associated with lower review scores | **Weak effect** | ~0.1 point range across burden levels (Q6) |
| H4 | Certain sellers/categories have disproportionately poor delivery performance | **Supported** | Seller late rates up to 32.6% vs 6.8% platform; category patterns (Q9, Q10) |
| H5 | First-order delivery experience differs between repeat and one-time customers | **Modest difference** | First order late: 5.7% (repeat) vs 6.8% (one-time) (Q8) |

## Results by question

### Q1. Delivery status (all orders with a delivery status)

| Status | Orders | Share |
|---|---|---|
| Early | 88,649 | 91.89% |
| On Time | 1,292 | 1.34% |
| Late | 6,535 | 6.77% |

Average delivery lead time (dashboard KPI): 12.41 days.

### Q3. Highest late rates by customer state (delivered orders)

| State | Orders | Late | Late % |
|---|---|---|---|
| AL | 397 | 85 | 21.41 |
| MA | 717 | 125 | 17.43 |
| SE | 335 | 51 | 15.22 |
| PI | 476 | 66 | 13.87 |
| CE | 1,279 | 176 | 13.76 |
| RJ | 12,350 | 1,495 | 12.11 |
| SP | 40,494 | 1,820 | 4.49 |

RJ is not the highest rate, but it has far more late orders than any small
Northeastern state.

### Q4-Q5. Delivery vs review score

| Delivery status | Avg review |
|---|---|
| Early | 4.29 |
| On Time | 4.03 |
| Late | 2.27 |

| Delay bucket | Avg review | Orders |
|---|---|---|
| Early | 4.29 | 88,658 |
| On-time | 4.03 | 1,291 |
| 1-3 days late | 3.29 | 1,856 |
| 4-7 days late | 2.10 | 1,756 |
| 8-15 days late | 1.68 | 1,610 |
| 15+ days late | 1.73 | 1,188 |

The penalty is steepest in the first week and then plateaus. Early deliveries score
higher than on-time ones (4.29 vs 4.03), which is consistent with customers valuing a
"pleasant surprise" and with conservative estimates, though this analysis cannot
confirm that explanation.

### Q6. Freight burden vs review score

| Freight burden | Avg review |
|---|---|
| Low | 4.07 |
| Medium | 4.06 |
| High | 4.03 |
| Very high | 3.97 |

### Q7-Q8. Repeat purchase

| Customer type | Customers | Share |
|---|---|---|
| One-time | 90,557 | 97.00% |
| Repeat | 2,801 | 3.00% |

| Customer type | Customers | Avg first review | Avg first delay (days) | First-order late % |
|---|---|---|---|---|
| One-time | 90,557 | 4.15 | -11.83 | 6.84 |
| Repeat | 2,801 | 4.20 | -12.70 | 5.71 |

### Q9. Sellers (30+ delivered orders)

- 13 sellers have late rates of 20% or more; the worst is 32.56% (43 orders, avg review 3.57), against 6.8% platform-wide.
- Several large sellers have moderate late rates but generate many poor reviews (for example, one seller with 1,772 orders at 9.71% late has 323 orders rated 1-2 stars). Rate and volume both matter.

Seller IDs are the anonymised hashes from the source data. See
`sql/05_sellers_categories.sql` for the full ranking query.

### Q10. Categories with poor reviews despite fair delivery

| Category (Portuguese / English) | Orders | Late % | Poor-review % |
|---|---|---|---|
| fashion_roupa_masculina / men's fashion | 112 | 4.72 | 26.13 |
| moveis_escritorio / office furniture | 1,273 | 8.05 | 22.80 |
| telefonia_fixa / landline telephony | 217 | 4.72 | 18.69 |
| audio / audio | 350 | 11.78 | 21.90 |

Audio is the one category where both delivery and product experience look weak.

## Recommended actions

| # | Finding | Recommended action | KPI to track |
|---|---------|--------------------|--------------|
| 1 | Reviews fall from 3.29 (1-3 days late) to 2.10 (4-7 days late), then plateau near 1.7 | When an order is likely to miss its promised date, notify the customer early with a new delivery date and offer a small make-good (for example a voucher). Reviews fall to about 2.1 once an order is 4+ days late, so test whether early contact softens that drop | % of late orders more than 3 days late; avg review of late orders |
| 2 | Late rates of 14-21% in AL, MA, SE, PI and CE vs ~4.5% in SP; RJ has 1,495 late orders at 12.1% | Check delivery services in states with high delays and set more realistic delivery dates based on past delivery times | Late % by state; late orders in RJ |
| 3 | 13 sellers (30+ orders) are 20%+ late; some high-volume sellers produce hundreds of poor reviews at moderate late rates | Create a seller scorecard to identify sellers with high late-delivery rates and poor reviews. Work with underperforming sellers to improve delivery and customer satisfaction | Late-delivery rate per seller; number of poor reviews per seller; average review score per seller |
| 4 | Men's fashion, office furniture and landline telephony: 5-8% late but 19-26% poor reviews | Review customer feedback for these categories and identify common problems with product quality or descriptions. Improve listings where needed | Poor-review % by category |
| 5 | Freight burden moves reviews by only ~0.1 points | Do not prioritise freight discounts to improve satisfaction; test them separately for conversion, which this analysis does not measure | n/a |
| 6 | Only 3.0% of customers repeat; first-order reviews are nearly identical (4.20 vs 4.15) | Fixing delivery alone is unlikely to lift repeat purchase much. Pilot retention levers (post-purchase follow-ups, replenishment or cross-sell offers) in an A/B test | Repeat rate; time to second order |

These are associations, not proven causes. Each action should be piloted and
measured before wide rollout.

## Data dictionary (key fields)

| Field | Meaning |
|---|---|
| `customer_id` | Generated per order. Use only to join `orders` to `customers`. |
| `customer_unique_id` | Identifies a real person across orders. Use for repeat behaviour. |
| `delivery_lead_time_days` | Delivered date minus purchase date. |
| `delivery_delay_days` | Delivered date minus estimated date (negative = early). |
| `delivery_status` | Early / On Time / Late; NULL if a date is missing. |
| `freight_ratio` | `freight_value / price` per order item. |
| `customer_type` | `repeat customer` if more than one delivered order, else `one-time customer`. |
