# R / Python calendar semantics: parity status

ADR 0002 designates R as the analytical reference and Python as the engineering implementation. This is an architectural intention, **not a demonstrated claim of numerical parity**.

The R sales generator reads the committed regional calendar and constructs weighted regional holiday and school-holiday intensity, then applies weekday and shutdown rules. The Python calendar pipeline fetches public holiday/school-holiday periods and generates date/state timing features; its primary output is a regional feature table rather than the same final sales-design matrix. These are not directly interchangeable without a shared comparison contract.

Before claiming parity, freeze an identical input period and states, document holiday-feature definitions and regional weights, export both final feature matrices at the same daily grain, and compare each shared feature with explicit tolerances. Differences in shutdown definitions must be reported rather than silently harmonized. Until then, R remains a historical analytical reference, not a verified oracle for every Python feature.
