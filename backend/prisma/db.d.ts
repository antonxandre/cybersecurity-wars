import 'dotenv/config';
import type { Contract } from './schema.d';
export declare const contract: Contract;
export declare const db: import("@prisma/orm-postgres/runtime").PostgresClient<Contract, import("@prisma/orm-family-sql/orm-client").NoCollectionClasses>;
