# Interfaces & Communication

UART transmit/receive with a baud generator, SPI master and slave (mode 0), a simplified I2C byte writer, parallel<->serial converters, a req/ack handshake, and synchronous FIFOs.

*Directory:* `src/interfaces/` -- 16 modules.

| Module | Description |
|--------|-------------|
| `fifo_sync_16x16` | Synchronous FIFO, 16 deep x 16-bit. |
| `fifo_sync_16x8` | Synchronous FIFO, 16 deep x 8-bit. |
| `fifo_sync_8x8` | Synchronous FIFO, 8 deep x 8-bit. |
| `handshake_sync` | 4-phase req/ack handshake synchronizer. |
| `i2c_master_byte` | Simplified I2C master byte writer (educational). |
| `parallel_to_serial16` | 16-bit parallel-in to serial-out converter. |
| `parallel_to_serial32` | 32-bit parallel-in to serial-out converter. |
| `parallel_to_serial8` | 8-bit parallel-in to serial-out converter. |
| `serial_to_parallel16` | 16-bit serial-in to parallel-out converter. |
| `serial_to_parallel32` | 32-bit serial-in to parallel-out converter. |
| `serial_to_parallel8` | 8-bit serial-in to parallel-out converter. |
| `spi_master8` | SPI master, mode 0, 8-bit full-duplex. |
| `spi_slave8` | SPI slave, mode 0, 8-bit. |
| `uart_baud_gen` | UART baud-rate tick generator. |
| `uart_rx8` | UART receiver, 8N1. |
| `uart_tx8` | UART transmitter, 8N1, baud-tick enabled. |
