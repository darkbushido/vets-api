# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Authenticating through ID.me', type: :request do
  context 'loa1 user' do
    it 'will authenticate user successfully' do
      post saml_callback_v1_sessions_path, params: { SAMLResponse: "<samlp:Response Destination='https://staging-api.va.gov/v1/sessions/callback' ID='FIMRSP_75e391e2-017c-14d4-bd53-f6e5dcadaa9d' InResponseTo='_2092cf97-66ed-462b-b2f5-b4d4e2586b03' IssueInstant='2021-10-12T19:03:40Z' Version='2.0' xmlns:ds='http://www.w3.org/2000/09/xmldsig#' xmlns:saml='urn:oasis:names:tc:SAML:2.0:assertion' xmlns:samlp='urn:oasis:names:tc:SAML:2.0:protocol' xmlns:xs='http://www.w3.org/2001/XMLSchema' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'><saml:Issuer Format='urn:oasis:names:tc:SAML:2.0:nameid-format:entity'>https://sqa.eauth.va.gov/isam/sps/saml20idp/saml20</saml:Issuer><ds:Signature Id='uuid75e391e3-017c-15e7-a2d4-f6e5dcadaa9d'><ds:SignedInfo><ds:CanonicalizationMethod Algorithm='http://www.w3.org/2001/10/xml-exc-c14n#'/><ds:SignatureMethod Algorithm='http://www.w3.org/2001/04/xmldsig-more#rsa-sha256'/><ds:Reference URI='#FIMRSP_75e391e2-017c-14d4-bd53-f6e5dcadaa9d'><ds:Transforms><ds:Transform Algorithm='http://www.w3.org/2000/09/xmldsig#enveloped-signature'/><ds:Transform Algorithm='http://www.w3.org/2001/10/xml-exc-c14n#'><xc14n:InclusiveNamespaces PrefixList='samlp saml xs ds xsi' xmlns:xc14n='http://www.w3.org/2001/10/xml-exc-c14n#'/></ds:Transform></ds:Transforms><ds:DigestMethod Algorithm='http://www.w3.org/2001/04/xmlenc#sha256'/><ds:DigestValue>qHUcAN65XvK/XgToAVci2qf8Q0dUGlWqMJr/JByNylE=</ds:DigestValue></ds:Reference></ds:SignedInfo><ds:SignatureValue>CJsagjLD9zpKfMTMi46q1WGI9x45f/T5TqjVN1C/vjiwyv/RAspPTIuLrtGcl5u+J/bTB0j/jFUgqzAoknAnwd7uCNa3UBGj607TGtbz+jPSTW8pWXqR3CQizZuINHEJs+V70451jPNAmMMCxU8fmpQBCi00SuIYi/dHWCJE6dDTn2MlR40vWn6bDqGE5V7iL989jOkCmzXIwLWHC+Fc/FxHFZ2N5cIJ+KGveNLNOEHq0j7agqRONKGM8ZR9Ul/1mluw4dxd1H+K/ow9Im3dPJOmcK3I7cMqSwxDZy2lFELPr8ptfjeH8B8V53F6/DrhxXhqykCtidRC3G8L8Wcf6J5yQkhNVZigo19/PohTjic+Ve1bDlpxMPqK4rdvA3hWwgTkqYAtGlOh5XqZpjMpXssC+/JgzjsafMzmGHq+YhC948Ey+4LoqmARbh8zzgO3hwPptK2m+kguSlUuRtefHCkazFODDuMzTfDpw6w3OMg8MNOxfNoYNEswame7RbpzTLx4VNB783UITW1GX/0ciIRBhzDSGHnAoLCDllVxAwS9rYUzdgVJe/ePzngdoNQW+L2i92f5dSjR0qW+xvi3XrNLPbkE9IXIqU6t47/+m4Zg+GiYa4pgxr78btfRJmFmA4rPysBRtsr6ChQVyav9t0cRv0PyZGM/8YlyRfojYCs=</ds:SignatureValue><ds:KeyInfo><ds:X509Data><ds:X509Certificate>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</ds:X509Certificate></ds:X509Data></ds:KeyInfo></ds:Signature><samlp:Status><samlp:StatusCode Value='urn:oasis:names:tc:SAML:2.0:status:Success'/></samlp:Status><saml:Assertion ID='Assertion-uuid75e391c0-017c-1497-a269-f6e5dcadaa9d' IssueInstant='2021-10-12T19:03:40Z' Version='2.0' xmlns:ds='http://www.w3.org/2000/09/xmldsig#' xmlns:saml='urn:oasis:names:tc:SAML:2.0:assertion' xmlns:xs='http://www.w3.org/2001/XMLSchema' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'><saml:Issuer Format='urn:oasis:names:tc:SAML:2.0:nameid-format:entity'>https://sqa.eauth.va.gov/isam/sps/saml20idp/saml20</saml:Issuer><ds:Signature Id='uuid75e391c1-017c-15aa-ade1-f6e5dcadaa9d' xmlns:ds='http://www.w3.org/2000/09/xmldsig#'><ds:SignedInfo><ds:CanonicalizationMethod Algorithm='http://www.w3.org/2001/10/xml-exc-c14n#'/><ds:SignatureMethod Algorithm='http://www.w3.org/2001/04/xmldsig-more#rsa-sha256'/><ds:Reference URI='#Assertion-uuid75e391c0-017c-1497-a269-f6e5dcadaa9d'><ds:Transforms><ds:Transform Algorithm='http://www.w3.org/2000/09/xmldsig#enveloped-signature'/><ds:Transform Algorithm='http://www.w3.org/2001/10/xml-exc-c14n#'><xc14n:InclusiveNamespaces PrefixList='' xmlns:xc14n='http://www.w3.org/2001/10/xml-exc-c14n#'/></ds:Transform></ds:Transforms><ds:DigestMethod Algorithm='http://www.w3.org/2001/04/xmlenc#sha256'/><ds:DigestValue>Rouln/1CtKvhjPxk58bIhBbyfDkWQIBtl4fDFthCEzY=</ds:DigestValue></ds:Reference></ds:SignedInfo><ds:SignatureValue>geOOWdk0QaB9CAo2NCxgI9NeLfN1RHNVqG2NeAySYwb4BgVdqiTNgX4bIpydGWBSi2GS9g8akeyG539GVMeVT449JopkfyMP9AcZ6BNxLWYvWrqX4aTbMVj7moZjoKue8Wi+fO0/YVl/nEX8GReq98PtwoZsRHqeLvG6SYBcfCfNMl/ss/PRdPgvNlhXjECOtmGwFFDtuZoDKodjhgEmh/zrgoBUPytgARqZi+aPu9fshNf5UMvi8SAIXMRC6si7mksU2ENKhPiuf7Vi1mfsHusWl2tvUXhrXylyAzRBxK/vf7MhewtDoEyWgmO74wJQgXpTqPpTkPc9Y+NQVgfSgnGEs/luKkeRVOvFG1rEyd2EfH7orTB71duD4JNrha1hjiS10hob8pGJ0PaKA3o8fd1mlO46wg7iQH2ncwpy9G2ArMu5gsY8hzdNb9/iW076L6pOdUMCFZraqiKDDT4mPtMjkoogbBW9HAyw/CPYO00KIzVtL9PEuzOMjeyFefnN9qp8vff46oWFSPJzjPZyQ11W1bjOKwl+wBwK/l5GgnKDusuTn3gv3QjPgB51KOQ9eL99S6g0VsYKG8FplQ/D+kRmhqlY1gbfl6ZJBweA8DvxCLjMPYGs6y9eIjK+YeoGx29scP2Mri2Gx//yOESXeXXhPGLzbNcEyOmyow8KboY=</ds:SignatureValue><ds:KeyInfo><ds:X509Data><ds:X509Certificate>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</ds:X509Certificate></ds:X509Data></ds:KeyInfo></ds:Signature><saml:Subject><saml:NameID Format='urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified'>200VIDM_edfb467dacf0445bb4ea92a8aa1fdaa2</saml:NameID><saml:SubjectConfirmation Method='urn:oasis:names:tc:SAML:2.0:cm:bearer'><saml:SubjectConfirmationData InResponseTo='_2092cf97-66ed-462b-b2f5-b4d4e2586b03' NotOnOrAfter='2021-10-12T19:08:40Z' Recipient='https://staging-api.va.gov/v1/sessions/callback'/></saml:SubjectConfirmation></saml:Subject><saml:Conditions NotBefore='2021-10-12T18:58:40Z' NotOnOrAfter='2021-10-12T19:08:40Z'><saml:AudienceRestriction><saml:Audience>https://ssoe-sp-staging.va.gov</saml:Audience></saml:AudienceRestriction></saml:Conditions><saml:AuthnStatement AuthnInstant='2021-10-12T19:03:40Z' SessionIndex='uuid95e0d30e-2b6c-484c-a23f-e9063635989d' SessionNotOnOrAfter='2021-10-12T20:03:40Z'><saml:AuthnContext><saml:AuthnContextClassRef>http://idmanagement.gov/ns/assurance/loa/1/vets</saml:AuthnContextClassRef></saml:AuthnContext></saml:AuthnStatement><saml:AttributeStatement><saml:Attribute Name='va_eauth_csid' NameFormat='urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified'><saml:AttributeValue>idme</saml:AttributeValue></saml:Attribute><saml:Attribute Name='va_eauth_lastname' NameFormat='urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified'><saml:AttributeValue>NOT_FOUND</saml:AttributeValue></saml:Attribute><saml:Attribute Name='va_eauth_aal_idme_highest' NameFormat='urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified'><saml:AttributeValue>2</saml:AttributeValue></saml:Attribute><saml:Attribute Name='va_eauth_credentialassurancelevel' NameFormat='urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified'><saml:AttributeValue>1</saml:AttributeValue></saml:Attribute><saml:Attribute Name='va_eauth_ial' NameFormat='urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified'><saml:AttributeValue>1</saml:AttributeValue></saml:Attribute><saml:Attribute Name='va_eauth_firstname' NameFormat='urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified'><saml:AttributeValue>NOT_FOUND</saml:AttributeValue></saml:Attribute><saml:Attribute Name='va_eauth_ial_idme_highest' NameFormat='urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified'><saml:AttributeValue>1</saml:AttributeValue></saml:Attribute><saml:Attribute Name='va_eauth_csponly' NameFormat='urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified'><saml:AttributeValue>true</saml:AttributeValue></saml:Attribute><saml:Attribute Name='va_eauth_aal' NameFormat='urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified'><saml:AttributeValue>2</saml:AttributeValue></saml:Attribute><saml:Attribute Name='va_eauth_emailaddress' NameFormat='urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified'><saml:AttributeValue>joeyn414+stagingidmetest@gmail.com</saml:AttributeValue></saml:Attribute><saml:Attribute Name='va_eauth_transactionid' NameFormat='urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified'><saml:AttributeValue>Xw9MMyQJ72Yir1rmmmZfPg+GVxuizkRmQXObbCQZj1o=</saml:AttributeValue></saml:Attribute><saml:Attribute Name='va_eauth_authncontextclassref' NameFormat='urn:ibm:names:ITFIM:5.1:accessmanager'><saml:AttributeValue>http://idmanagement.gov/ns/assurance/loa/1/vets</saml:AttributeValue></saml:Attribute><saml:Attribute Name='va_eauth_uid' NameFormat='urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified'><saml:AttributeValue>edfb467dacf0445bb4ea92a8aa1fdaa2</saml:AttributeValue></saml:Attribute><saml:Attribute Name='va_eauth_issueinstant' NameFormat='urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified'><saml:AttributeValue>2021-10-12T19:03:38Z</saml:AttributeValue></saml:Attribute><saml:Attribute Name='va_eauth_middlename' NameFormat='urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified'><saml:AttributeValue>NOT_FOUND</saml:AttributeValue></saml:Attribute><saml:Attribute Name='va_eauth_multifactor' NameFormat='urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified'><saml:AttributeValue>true</saml:AttributeValue></saml:Attribute><saml:Attribute Name='va_eauth_vagov_saml_request_artifact' NameFormat='urn:ibm:names:ITFIM:5.1:accessmanager'><saml:AttributeValue>{\"timestamp\":\"2021-10-12T19:00:51+00:00\",\"transaction_id\":\"c4957fdc-4259-4ba6-9813-867729071dca\",\"saml_request_id\":\"_2092cf97-66ed-462b-b2f5-b4d4e2586b03\",\"saml_request_query_params\":{}}</saml:AttributeValue></saml:Attribute></saml:AttributeStatement></saml:Assertion></samlp:Response>" }
    end
  end
end
