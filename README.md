#**Comprice – Intelligent Daily Necessities Price Optimisation System**

This is a mobile application developed to help Malaysian consumers make more informed purchasing decisions when buying daily necessities. It provides product price comparison, location-based store recommendations, shopping basket optimisation, and OCR-assisted price discrepancy complaint preparation within a single application.

The system uses historical price data from the KPDN PriceCatcher dataset to help users compare product prices across retail premises and identify potentially cost-effective shopping options.

##**Features**

1. Product Browsing and Price Comparison
- Browse daily necessity products by category and item group.
- Search for specific products.
- Compare product prices across different retail premises.
- View product details, store information, and price information.
- Save frequently viewed products to favourites.

2. Basket Optimisation
- Generate single-store shopping recommendations.
- Generate multi-store shopping recommendations involving combinations of up to two retail premises.
- Identify available products and compare basket costs.
- Consider estimated travel costs when evaluating shopping options.
- Use geographical filtering and road-distance calculations to identify suitable retail premises.

3. Price Discrepancy Complaint Reporting
- Capture images of retail price tags.
- Extract product and price information using Google ML Kit OCR.
- Allow users to review and edit extracted information.
- Prepare structured complaint information.
- Support complaint submission through KPDN's official complaint channels.

4. Price Notifications
- Allow users to set target prices for selected products.
- Monitor available product prices against users' target prices.
- Consider geographical and road-distance preferences when identifying relevant premises.
- Send push notifications through Firebase Cloud Messaging when qualifying prices are found.

5. User Management
- User registration and authentication.
- User profile management.
- Biometric login support.
- Favourites and personalised price notifications.
