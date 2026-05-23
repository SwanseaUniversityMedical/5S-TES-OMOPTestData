FROM python:3.12-slim

WORKDIR /app

# Install psycopg2 (binary wheel – no libpq-dev needed)
RUN pip install --no-cache-dir psycopg2-binary

COPY load.py .

CMD ["python", "-u", "load.py"]
