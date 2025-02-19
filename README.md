# Amplify Flutter Demo Shopping App

A Flutter shopping application demonstrating the integration of AWS Amplify services for backend functionality.

## Screenshots

Account creation with email verification

<img src="docs/images/account_creation.png" height="400" />

Product listing

<img src="docs/images/product_list.png" height="400" />

Product details

<img src="docs/images/product_details.png" height="400" />

Product update

<img src="docs/images/product_update.png" height="400" />

Shopping cart

<img src="docs/images/cart_page.png" height="400" />

## Data Model

The application uses AWS AppSync GraphQL API with the following schema ([file](amplify/backend/api/demoshoppingapp/schema.graphql)):

```graphql
type Product @model @auth(rules: [
  { allow: owner },
  { allow: public, operations: [read] }
]) {
  id: ID!
  name: String!
  description: String
  stock: Int!
  price: Float!
}
```

The schema defines a Product model with:

- Authentication rules allowing owners full access and public read-only access
- Required fields: id, name, stock, and price
- Optional field: description

## AWS Services Used

1. **AWS AppSync**
   - Provides GraphQL API for product management
   - Handles real-time data synchronization

2. **Amazon Cognito**
   - User authentication and authorization
   - Manages user sessions and tokens

3. **AWS Amplify Gen 1**
   - Backend infrastructure management
   - API integration and configuration

## Project Structure

### `/lib` Directory Organization

- `/bloc`: Contains the Flutter Bloc implementation (events, states, and bloc for products)
- `/config`: Configuration files and constants
- `/models`: Generated GraphQL model classes + CartItem model
- `/pages`: Flutter UI screens and widgets
- `/router`: Application routing configuration
- `/services`: Business logic and API service layers (ProductRepository, ShoppingCart)

### Key Features

1. **Authentication**
   - User sign-up and sign-in using Amplify Authenticator
   - Logout button available on every page

2. **Product Management**
   - Create, read, update, and delete products
   - Automatic refresh of product listing, details, and cart after create/update/delete operations
   - Stock and price management


## Getting Started

1. Install dependencies:

   ```bash
   flutter pub get
   ```

2. Configure Amplify:

   ```bash
   amplify init
   amplify push
   ```

3. Run the application:

   ```bash
   flutter run
   ```

Make sure you have the AWS Amplify CLI and Flutter installed on your development machine.
