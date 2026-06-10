BEGIN TRANSACTION;

CREATE TABLE IF NOT EXISTS customers (
    customer_id INTEGER PRIMARY KEY,
    full_name TEXT NOT NULL,
    email TEXT UNIQUE,
    phone TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS staff (
    staff_id INTEGER PRIMARY KEY,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL,
    email TEXT UNIQUE,
    hired_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS print_products (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL UNIQUE,
    base_price NUMERIC NOT NULL CHECK (base_price >= 0),
    active INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0, 1))
);

CREATE TABLE IF NOT EXISTS print_jobs (
    job_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    handled_by_staff_id INTEGER,
    job_status TEXT NOT NULL DEFAULT 'pending' CHECK (job_status IN ('pending', 'in_progress', 'completed', 'cancelled')),
    due_date TEXT,
    notes TEXT,
    total_amount NUMERIC NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (handled_by_staff_id) REFERENCES staff(staff_id)
);

CREATE TABLE IF NOT EXISTS job_items (
    item_id INTEGER PRIMARY KEY,
    job_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price >= 0),
    line_total NUMERIC NOT NULL CHECK (line_total >= 0),
    specifications TEXT,
    FOREIGN KEY (job_id) REFERENCES print_jobs(job_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES print_products(product_id)
);

CREATE TABLE IF NOT EXISTS payments (
    payment_id INTEGER PRIMARY KEY,
    job_id INTEGER NOT NULL,
    paid_amount NUMERIC NOT NULL CHECK (paid_amount > 0),
    payment_method TEXT NOT NULL CHECK (payment_method IN ('cash', 'card', 'upi', 'bank_transfer', 'other')),
    paid_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reference_note TEXT,
    FOREIGN KEY (job_id) REFERENCES print_jobs(job_id) ON DELETE CASCADE
);

CREATE TRIGGER IF NOT EXISTS trg_job_items_after_insert
AFTER INSERT ON job_items
BEGIN
    UPDATE print_jobs
    SET total_amount = (
        SELECT COALESCE(SUM(line_total), 0)
        FROM job_items
        WHERE job_id = NEW.job_id
    ),
    updated_at = CURRENT_TIMESTAMP
    WHERE job_id = NEW.job_id;
END;

CREATE TRIGGER IF NOT EXISTS trg_job_items_prevent_job_move
BEFORE UPDATE OF job_id ON job_items
WHEN NEW.job_id <> OLD.job_id
BEGIN
    SELECT RAISE(ABORT, 'Changing job_id for an existing job item is not allowed');
END;

CREATE TRIGGER IF NOT EXISTS trg_job_items_after_update
AFTER UPDATE ON job_items
BEGIN
    UPDATE print_jobs
    SET total_amount = (
        SELECT COALESCE(SUM(line_total), 0)
        FROM job_items
        WHERE job_id = NEW.job_id
    ),
    updated_at = CURRENT_TIMESTAMP
    WHERE job_id = NEW.job_id;
    UPDATE print_jobs
    SET total_amount = (
        SELECT COALESCE(SUM(line_total), 0)
        FROM job_items
        WHERE job_id = OLD.job_id
    ),
    updated_at = CURRENT_TIMESTAMP
    WHERE job_id = OLD.job_id
      AND OLD.job_id <> NEW.job_id;
END;

CREATE TRIGGER IF NOT EXISTS trg_job_items_after_delete
AFTER DELETE ON job_items
BEGIN
    UPDATE print_jobs
    SET total_amount = (
        SELECT COALESCE(SUM(line_total), 0)
        FROM job_items
        WHERE job_id = OLD.job_id
    ),
    updated_at = CURRENT_TIMESTAMP
    WHERE job_id = OLD.job_id;
END;

CREATE INDEX IF NOT EXISTS idx_print_jobs_customer_id ON print_jobs(customer_id);
CREATE INDEX IF NOT EXISTS idx_print_jobs_status ON print_jobs(job_status);
CREATE INDEX IF NOT EXISTS idx_job_items_job_id ON job_items(job_id);
CREATE INDEX IF NOT EXISTS idx_payments_job_id ON payments(job_id);

COMMIT;
