# 🚀 SPI Master/Slave 통신 프로젝트

이 프로젝트는 FPGA에서 SystemVerilog로 구현된 **SPI Master**와 **SPI Slave** 모듈을 포함합니다.

Master는 내부 카운터의 값을 SPI를 통해 전송하고, Slave는 SPI를 통해 수신한 데이터를 4-digit 7-segment (FND) 디스플레이에 표시합니다. 두 모듈이 `TOP.sv` 파일 안에 각각 구현되어 있어, SPI 통신 프로토콜의 송신과 수신 로직을 테스트하고 이해하는 데 적합합니다.

## ⚙️ 프로젝트 기능

* **SPI Master:** 16-bit 내부 카운터 값을 8-bit 단위로 나누어 2-byte SPI 패킷으로 전송합니다.
* **SPI Slave:** 2-byte SPI 패킷을 수신하여 16-bit 데이터로 재조합합니다.
* **FND 디스플레이:** Slave가 수신한 16-bit 데이터를 4-digit 7-segment 디스플레이에 10진수로 표시합니다.
* **입력 제어:** `runstop` 버튼으로 Master의 카운터 동작을 제어하고, `clear` 버튼으로 리셋합니다.

## 📦 프로젝트 구조

이 프로젝트는 크게 **Master Block**, **Slave Block**, 그리고 이 둘을 래핑하는 **Top Module**로 구성됩니다.

### 1. Master Block

Master 블록은 `runstop` 및 `clear` 입력에 따라 16-bit 카운터를 동작시키고, 이 값을 `spi_master` 모듈을 통해 2-byte(상위 8-bit, 하위 8-bit)로 나누어 전송합니다.

* `MASTER.sv`: `upcounter`와 `spi_master` 모듈을 연결하는 래퍼입니다.
* `upcounter.sv`: 100Hz 틱을 생성하여 16-bit 카운터를 구동하고, `spi_master`의 `start` 신호를 제어하는 FSM(`up_counter_cr`)을 포함합니다.
* `spi_master.sv`: 8-bit 데이터를 SPI 프로토콜에 맞게 직렬화하여 `mosi`와 `sclk`로 전송하는 FSM(`spi_master`)입니다.

### 2. Slave Block

Slave 블록은 외부 SPI Master로부터 2-byte의 데이터를 수신하고, 이를 16-bit 값으로 재조합합니다. 이 값은 `fnd_controller`로 전달되어 4-digit FND에 표시됩니다.

* `SLAVE.sv`: `spi_slave`, `slave_cu`, `fnd_controller` 모듈을 연결하는 래퍼입니다.
* `spi_slave.sv`: `sclk`에 맞춰 `mosi` 데이터를 수신하여 8-bit 병렬 데이터(`rx_data`)를 생성합니다. `slave_cu` FSM은 2-byte 수신을 관리하여 16-bit `fnd_data`를 만듭니다.
* `fnd_controller.sv`: 입력된 14-bit 데이터를 4자리의 10진수로 분리하고(`digit_splitter`), 이를 동적 구동(multiplexing) 방식으로 7-segment 디스플레이에 표시합니다.

### 3. Top Module 및 유틸리티

* `TOP.sv`: 최상위 모듈로, `MASTER`와 `SLAVE` 블록을 인스턴스화하고 FPGA의 실제 I/O 핀(버튼, FND, SPI 핀)에 연결합니다.
* `button_debounce` (`TOP.sv` 내): `runstop`, `clear` 버튼 입력의 채터링(chattering)을 제거합니다. (현재 `TOP.sv`에서는 주석 처리되어 있습니다).

## 🎛️ 모듈 상세 설명

| 파일명 | 주요 모듈명 | 설명 |
| :--- | :--- | :--- |
| `TOP.sv` | `TOP` | 최상위 모듈. Master와 Slave 블록을 인스턴스화하고 I/O에 연결합니다. |
| `MASTER.sv` | `MASTER` | Master 로직의 래퍼(wrapper) 모듈. `upcounter`와 `spi_master`를 연결합니다. |
| `spi_master.sv` | `spi_master` | SPI Master FSM. 8-bit 데이터를 직렬화하여 전송합니다. |
| `upcounter.sv` | `up_counter_cr` | 16-bit 카운터 값을 2-byte SPI 패킷으로 전송하도록 Master FSM을 제어합니다. |
| `SLAVE.sv` | `SLAVE` | Slave 로직의 래퍼 모듈. `spi_slave`, `slave_cu`, `fnd_controller`를 연결합니다. |
| `spi_slave.sv` | `spi_slave`, `slave_cu` | SPI Slave FSM. 직렬 데이터를 8-bit로 병렬화하고, `slave_cu`가 2-byte를 16-bit로 재조합합니다. |
| `fnd_controller.sv`| `fnd_controller` | 4-Digit FND 컨트롤러. 14-bit 입력을 10진수로 변환하여 FND에 표시합니다. |

## 💡 사용 방법

1.  FPGA 보드에 맞게 `.xdc` 제약 파일을 설정하여 `TOP.sv`의 포트들을 실제 핀에 매핑합니다.
2.  디자인을 합성(Synthesis) 및 구현(Implementation)한 후 FPGA에 업로드합니다.
3.  **Master 테스트:**
    * `runstop` 버튼을 누르면 카운터가 동작을 시작합니다.
    * 로직 애널라이저를 `spi_master_mosi`, `spi_master_sclk`, `spi_master_ss` 핀에 연결하면 16-bit 카운터 값이 2-byte로 나뉘어 지속적으로 전송되는 것을 관찰할 수 있습니다.
4.  **Slave 테스트:**
    * 외부 SPI Master 장치(예: 다른 FPGA, MCU, Raspberry Pi 등)를 `spi_slave_mosi`, `spi_slave_sclk`, `spi_slave_ss` 핀에 연결합니다.
    * 외부 Master에서 2-byte 데이터를 전송하면, 해당 값이 16-bit로 조합되어 보드의 4-digit FND에 10진수 숫자로 표시됩니다.
