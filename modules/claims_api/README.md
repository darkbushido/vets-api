# Benefits Claims API

## Connecting to upstream services locally
Note: Ensure correct localhost url with port is configured in your settings.local.yml

##### BGS
ssh -L 4447:localhost:4447 {{aws-url}}

##### EVSS
ssh -L 4431:localhost:4431 {{aws-url}}

## OpenApi/Swagger Doc Generation
This api uses [rswag](https://github.com/rswag/rswag) to build the OpenApi/Swagger docs that are displayed in the [VA|Lighthouse APIs Documentation](https://developer.va.gov/explore/benefits/docs/claims?version=current).  To generate/update the docs for this api, navigate to the root directory of `vets-api` and run the following command ::
- `rake rswag:claims_api:run`


## License
[CC0 1.0 Universal Summary](https://creativecommons.org/publicdomain/zero/1.0/legalcode).
