# FIFO UVM 테스트벤치

동기식 FIFO의 데이터 순서와 full·empty 상태를 Scoreboard로 비교하고, Directed 및 Random 시나리오를 구성하였습니다.

- 수행 시기 2026.09
- 참여 형태 개인
- 담당 범위 UVM 환경 구성, Queue 참조 모델 및 기능 커버리지 작성

[포트폴리오 상세 페이지](https://eugeneson3.github.io/projects/fifo-uvm/)

## 프로젝트 목표

동기식 FIFO의 데이터 보존, 출력 순서, full·empty 상태 및 동시 push/pop 동작을 자동으로 비교하는 검증 환경을 구성하는 것을 목표로 하였습니다.

## 설계 및 구현

- Sequence·Sequencer·Driver·Monitor·Scoreboard·Coverage를 UVM 컴포넌트로 구성하였습니다.
- 현재 소스는 Reset 3회, Push 17회, Pop 17회, Random 1,000회 시나리오를 수행합니다.
- Scoreboard는 수락된 쓰기 데이터를 Queue에 저장하고 읽기 데이터 및 플래그를 예상 상태와 비교합니다.
- push, pop, full, empty, 데이터 및 push×pop·push×full·pop×empty 커버리지를 수집합니다.

## Troubleshooting

### 구동·관측 타이밍

DUT 갱신 시점과 테스트벤치 구동·관측 시점을 정의해야 합니다.

같은 클럭 에지에서 신호 구동과 샘플링을 수행하면 시뮬레이션 스케줄링의 영향을 받을 수 있습니다.

소스에서 Driver의 output #1과 Monitor의 input #1step clocking block을 사용하였습니다.

구동·관측 시점과 Scoreboard의 이전 상태 기반 비교 순서를 명시하였습니다.

### X 상태 처리와 검사 범위

현재 Scoreboard는 reset 또는 full·empty의 X 상태에서 예상 Queue를 초기화합니다.

초기 상태 처리 경로에 실행 중 X 상태가 포함되어 있습니다.

실행 중 X 발생의 독립 오류 판정과 종료 시 잔여 데이터 검사를 후속 검토 항목으로 정리하였습니다.

현재 저장소의 검증 범위에 해당 제한을 기록하였습니다.

## 검증 및 결과

- 발표 자료의 결과 화면에 데이터 비교 5,355건, 불일치 0건, Functional Coverage 100%가 기록되어 있습니다.
- 현재 소스와 발표 시나리오 설명은 Random 1,000회입니다. 결과 화면의 실행 횟수와 차이가 있어 동일 실행 결과로 확정하지 않았습니다.

## 소스코드 구조

2026_09_06_FIFO_UVM의 소스를 수록하였습니다. 발표 결과 이미지와 현재 소스의 실행 횟수 차이를 기록하였으며, UVM 시뮬레이터를 통한 이번 재실행 결과는 포함하지 않았습니다.

| 경로 | 내용 |
| --- | --- |
| [fifo.sv](fifo.sv) | 동기식 FIFO RTL |
| [tb_fifo.sv](tb_fifo.sv) | Interface 및 UVM 검증 컴포넌트 |
| [files.f](files.f) | 소스 컴파일 순서 |
| [README.md](README.md) | 검증 구성과 발표 결과의 버전 정보 |

## 실행 방법

1. UVM 1.2를 지원하는 SystemVerilog 시뮬레이터에서 files.f를 컴파일합니다.
2. UVM 패키지와 매크로 include 경로를 설정하고 tb_fifo를 최상위로 지정합니다.
3. 테스트벤치의 FSDB 출력 함수를 사용하려면 시뮬레이터에 FSDB PLI를 연결하고 build/ 디렉터리를 생성합니다.
4. UVM_ERROR·UVM_FATAL, Scoreboard summary, coverage 출력을 확인합니다.

## 참고 자료

- [발표 자료](https://docs.google.com/presentation/d/1rK8uxAa0HYDFaz_O0OAxC-YbhmIWZcK8dsZ-IXDrIas/edit)

## 소스 이력

2026년 11월 18일 로컬 프로젝트에서 구성한 공개 스냅샷입니다. 원본 파일의 상대 경로와 SHA-256은 [SOURCE_MANIFEST.json](SOURCE_MANIFEST.json)에 기록하였습니다. 빌드 산출물과 로컬 개발 환경은 제외하였습니다. 파일별 저작권 및 라이선스 고지를 유지하였습니다.
