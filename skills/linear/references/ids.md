# Linear Reference IDs

## Workspaces

This repo works across three Linear workspaces: Stellar, Kickplan, and Meerkat. Each has its own teams, workflow state IDs, and user IDs. The MCP tools are namespaced: `linear_stellar_*`, `linear_kickplan_*`, `linear_meerkat_*`.

---

## Stellar

### User
- **Will Clark**: `1309cd90-e208-46aa-9537-93c16532306e`

### Teams
| Team | ID |
|------|----|
| Platform | `8707cd45-2b54-4013-8378-fecda2f0e05a` |
| Infrastructure | `429e2e9d-493f-4ebd-82c0-158ab5cf1eb5` |
| Players | `cc1c067f-b7e3-4b87-a0ee-aa0350c30e38` |

### Workflow States (per team)

**Platform**
| State | ID | Type |
|-------|----|------|
| Backlog | `849eb4fe-b2f9-4090-aceb-e66f52ac7577` | backlog |
| Todo | `033c7c6e-5e93-4507-bf94-78bb434ad648` | unstarted |
| Ready for Research | `7f4f185a-94d9-4836-99bc-237e32937d15` | unstarted |
| In Research | `535a0370-6682-4c50-b7d3-f78cabbc30c3` | started |
| Ready For Plan | `df5b63d7-051c-4689-8e90-e58a600fdf66` | unstarted |
| In Plan | `fbe8a9d9-7e39-4f98-916a-8dbf9db60285` | started |
| In Progress | `099a692e-c921-4a3a-921f-c1b013e1222e` | started |
| In Review | `609a18b6-8242-4cbc-b7b9-a6f0747e74ea` | started |
| Done | `404bb310-3984-476b-b378-c3856dac536e` | completed |
| Canceled | `f7655c92-7600-4a88-9a75-11ceb6be3371` | canceled |
| Duplicate | `b3de7e9b-0a59-423e-9c4c-8883af73d5fe` | canceled |

**Infrastructure**
| State | ID | Type |
|-------|----|------|
| Backlog | `2986d7eb-40e9-4512-a2d3-c870056c219c` | backlog |
| Todo | `8a9dfac0-6001-4f3d-af52-31f2799f55ab` | unstarted |
| Ready For Research | `2b0b7036-4ed1-4e4b-bbea-d7a8b74cd5f3` | unstarted |
| In Research | `2b173449-6a72-42c7-a815-4147477d5fcf` | started |
| Ready for Plan | `b75d69b0-5e9b-4508-b8c6-bb7aa496c36e` | unstarted |
| In Plan | `7907ff48-c43d-4523-9257-e402b0dd4f9c` | started |
| In Progress | `30cbcf5a-31ac-4fb5-9189-f2640abf0a90` | started |
| In Review | `e8da7cd2-a91c-42b6-bb28-6cbf4c5166ce` | started |
| Done | `90498808-ea1f-41f3-ab24-0d97eb1b9921` | completed |
| Canceled | `533c44f2-2346-4193-8d59-276ecbbc9d68` | canceled |
| Duplicate | `2cf2898c-2cec-4c06-9cc4-4080b6bc86aa` | canceled |

**Players**
| State | ID | Type |
|-------|----|------|
| Backlog | `6a1cf4c0-e0fb-4726-a0f7-7b109f3072b0` | backlog |
| Todo | `f714f4c7-a1df-43df-bab3-908f1f7dc712` | unstarted |
| Ready For Research | `95aa54ee-f1c5-4b84-b4db-6534a79bbe0e` | unstarted |
| In Research | `8dc6fb88-75e4-418c-8fd1-0e9bf9562503` | started |
| Ready for Plan | `3056a53d-12fb-427f-a64c-0cd4c15d4565` | unstarted |
| In Plan | `01228523-51fa-48cf-b2d5-1cd16f0f3e0f` | started |
| In Progress | `34310b61-a697-4776-940a-8b20bdaee6da` | started |
| In Review | `0e4675c6-96ba-49bd-8a35-15e5ed74ec24` | started |
| Done | `79989858-ac35-4d46-9b7e-4017958213a4` | completed |
| Canceled | `a600b66f-59a2-4d91-bcea-3645a7e61397` | canceled |
| Duplicate | `2fdd1074-ab3e-458c-9403-e3cc0291e6e2` | canceled |

### Labels
| Label | ID | Description |
|-------|----|-------------|
| Bug | `558f9100-c8f8-4137-8f3f-d4e48c804d42` | |
| Feature | `0dbc728e-8717-4cfb-b6bc-ef586997fdac` | |
| Improvement | `a399a5a7-5ed7-4821-9c36-5c419995053d` | |
| Auth | `6aba260f-16a6-4894-8115-3cfce8238014` | Firebase auth, stream-authenticate, SSO |
| Chat | `2b0dcc8c-492a-423f-b65b-9a8bc3628866` | Elixir chat service, IRC infrastructure, real-time messaging |
| Integrations | `ad9353a4-aa86-4c36-a3ce-e1ff10e48c7b` | Zapier, Zendesk, third-party service connections |
| Observability | `3110ee99-69ed-4e58-9b86-561acf6581f5` | OpenTelemetry, Sentry, logging, monitoring |
| Payments | `e3842c4e-0102-42de-b724-9d855651d653` | Stripe Connect, bank-import, payouts, billing |
| Streaming | `8daea90b-714d-4b4a-88d4-6b6c5c2d8e29` | MediaLive, MediaPackage, ingest pipelines, video encoding |

---

## Kickplan

### User
- **Will Clark**: `638f8955-37d4-4718-9cba-00bfcd561ebd`

### Teams
| Team | ID |
|------|----|
| Platform | `18f9a188-91c1-47c2-acc2-a46afb212b53` |
| Infra | `a28bfd20-3686-4644-93da-90c80a809270` |
| SDKs | `05d55d9a-3401-4304-8122-c596df0e14e2` |
| Chargebacks | `99396604-7cb8-4a3b-b45c-80c340a3c927` |

### Workflow States (per team)

**Platform**
| State | ID | Type |
|-------|----|------|
| Backlog | `8ddc1c51-aedb-4e36-869d-3d8b94d82f1d` | backlog |
| Todo | `a83bd36a-7d59-4d27-ab5e-4a040381e706` | unstarted |
| Ready for Research | `21c2b2e0-d865-49aa-8ac0-b0d9f17e56b8` | unstarted |
| In Research | `6cd0ff0f-864f-4303-937f-d2c79c63c9eb` | started |
| Ready For Plan | `df387ea0-f2f0-4df3-8d89-7bae78d3fc16` | unstarted |
| In Plan | `1e9bda4f-13cf-4397-b39c-7d002430ef34` | started |
| In Progress | `9e782665-96cb-4ac9-8e4d-9b4c9f18e072` | started |
| In Review | `15fea0ca-d88e-407d-9896-3cdaa52f8fd1` | started |
| Done | `7817b47c-6c7a-4ef6-ac48-4c2fb97783d4` | completed |
| Canceled | `f3ee5e45-0ce8-4846-8d91-02f761acef7b` | canceled |
| Duplicate | `909ba9f6-100b-4fad-b569-e1da13e30cc3` | canceled |

**Infra**
| State | ID | Type |
|-------|----|------|
| Backlog | `79faa802-4d29-4f9e-8aa9-cbd52ad72924` | backlog |
| Todo | `0d065a5f-c845-4b6c-a5fb-c40f6d2d95dd` | unstarted |
| Ready for Research | `36639c5e-7b61-4385-9ec8-d12b4ea9267c` | unstarted |
| In Research | `e1e123e4-b5c8-495c-97f6-53e3b1d77640` | started |
| Ready For Plan | `3cab9cc5-3e7f-4787-9a85-757e1c68dbce` | unstarted |
| In Plan | `5cb3c2ef-5113-4ff4-9faa-23a07694f3b4` | started |
| In Progress | `ab7e5ebc-aaeb-402b-af63-f664c1783355` | started |
| In Review | `a1248a15-2d3a-49a0-bdc3-15c67f5a69be` | started |
| Done | `c1cbf876-3299-4fa5-97ab-ea8ec9e257e7` | completed |
| Canceled | `be563794-0218-43ef-bfa2-6cd9618e63a7` | canceled |
| Duplicate | `7f2d14fe-61dc-464c-9e1c-a3a733dafd8a` | canceled |

**SDKs**
| State | ID | Type |
|-------|----|------|
| Backlog | `4d8b4ca3-aa44-4662-aa69-97f164b7675b` | backlog |
| Todo | `f879dfd6-19a8-493a-9e19-5c219d6f1859` | unstarted |
| Ready For Research | `d648949c-57a1-4e71-a126-db7bae64d4ed` | unstarted |
| In Research | `b70f9563-214c-4044-9940-67231c3fecf8` | started |
| Ready For Plan | `f75bf35b-82ea-422a-977b-a1582b26cbf5` | unstarted |
| In Plan | `07d09117-c061-44de-baa2-e4af2b3b2aa4` | started |
| In Progress | `e3783a76-09ac-4b24-a00b-e528eefeaf7e` | started |
| In Review | `03c78c66-1a4f-4b92-972b-98d49288fc5c` | started |
| Done | `7e65e956-e049-4ed8-a63b-fc2eb8e53bf0` | completed |
| Canceled | `7a293734-d178-41e7-bcea-bc525b9b8799` | canceled |
| Duplicate | `896316f9-d421-4b71-9cfc-b88b9eee5e6a` | canceled |

**Chargebacks**
| State | ID | Type |
|-------|----|------|
| Backlog | `89abcc8b-e1d1-4f10-9816-64d59612ffa4` | backlog |
| Todo | `1c929096-b5d5-4e0e-8772-549b9b1070c8` | unstarted |
| Ready for Research | `80c33b16-75a5-48d3-8650-2dc1c92292d4` | unstarted |
| In Research | `36149310-f2de-49e3-9da5-753af6f50132` | started |
| Ready for Plan | `0d6ce403-a4f9-4e93-aa61-6e84275bbd3d` | unstarted |
| In Plan | `762eb1fa-75bb-4e58-9844-c7e65077586a` | started |
| In Progress | `28ea6db2-35e8-414b-bc13-2e3cdbf299c4` | started |
| In Review | `7060b69a-25f1-4708-bb9b-b6aa7568dd13` | started |
| Done | `7bac54ba-c524-4ab7-92dc-7abca763da17` | completed |
| Canceled | `6a427e26-98d9-42e3-b9c8-e96d4b2fb149` | canceled |
| Duplicate | `f9591d8b-6f64-41a4-8061-c0fd1a8bad6e` | canceled |

### Labels
| Label | ID | Description |
|-------|----|-------------|
| Bug | `f4c1a4e0-b07d-46db-ad64-da6433141a91` | |
| Feature | `a97926f5-607f-4938-a8d4-f24e7d313d3f` | |
| Improvement | `150d976a-1cf7-421b-af05-b7aafbe83bd8` | |
| API | `291b9eb8-5544-4820-89dd-6e0dcc4ee06f` | GraphQL, JSON-RPC protocol layer, API design and contracts |
| Auth & Access | `839bc727-11da-4011-acc6-e06efda0f210` | Account management, RBAC, API keys, authentication flows |
| Developer Experience | `a00344ee-c41d-4a75-b015-0719c801aa44` | SDK docs, onboarding, API ergonomics, integration guides |
| Observability | `6932a561-2d8a-425a-aaf9-4338547bbaac` | Metrics, logging, monitoring, alerting across all services |
| Payments & Billing | `5518d024-2dea-4751-8362-588565006ac4` | Stripe integration, chargebacks, billing flows |
| Performance | `e9795b0d-c9df-4f5b-8f71-5dc0b3e79a77` | Optimization, benchmarking, latency reduction |
| Security | `b4684f45-b5e2-40e0-9a7b-5b4ea5d6b237` | Vulnerabilities, hardening, compliance, audit |

---

## Meerkat

### User
- **Will Clark**: `484610ed-9f6b-4536-92e6-c82cd3fcd8f8`

### Teams
| Team | ID |
|------|----|
| Meerkat Collective | `be5bb207-bab4-4352-b834-a3bcfce83753` |
| Tightbeam | `0497c4a2-093f-481d-8e7b-b34bd3d2d95a` |
| Recoup | `d57ba45d-b58d-494e-9588-04faa72d0e2c` |

### Workflow States (per team)

**Tightbeam**
| State | ID | Type |
|-------|----|------|
| Backlog | `776a9fea-9800-4069-8235-55430dfccf1e` | backlog |
| Todo | `e7e2de34-4d1a-43d0-9274-3a43dda57ad2` | unstarted |
| Ready for Research | `82b875b1-543e-4a15-a47c-56eb694c753a` | unstarted |
| In Research | `0135f0a2-6fe6-4a60-8063-f2436dba63a2` | started |
| Ready for Plan | `6f12efea-a608-4941-a6e1-0cab1a136a8a` | unstarted |
| In Plan | `ad756c88-d878-45e0-8d6a-3794939767fb` | started |
| In Progress | `5ffa6462-31ca-4c61-9246-ca1487de8495` | started |
| In Review | `7b53c66b-9410-49f3-b340-f9ea5888be4e` | started |
| Done | `0571ae80-5afe-493a-8f78-d37c473ee31d` | completed |
| Canceled | `abecda03-cd8e-41d3-92ee-0a7d8c04e33a` | canceled |
| Duplicate | `17c79c2c-7e87-417f-8c4f-9181ed55f2eb` | canceled |

### Labels
| Label | ID | Description |
|-------|----|-------------|
| Bug | `24fc6c25-4dea-448f-9175-c888d93c0c0d` | |
| Feature | `1377f6e2-d2be-4f1e-ba8a-2aaf5cf9bb51` | |
| Improvement | `b5eaaf65-e6c8-426d-be45-781270a7d083` | |

---

## Workflow

All teams follow the same workflow:

```
Backlog -> Todo -> Ready for Research -> In Research -> Ready for Plan -> In Plan -> In Progress -> In Review -> Done
```

Canceled and Duplicate are terminal states available from any step.

## Tagging Users

Tag Will in descriptions and comments using `@[Will Clark](USER_ID)` format, using the appropriate user ID for the workspace.
