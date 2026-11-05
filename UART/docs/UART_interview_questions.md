# UART Interview Questions and Answers

These questions cover UART fundamentals and the design in this folder. The
implemented transmitter and receiver use 8 data bits, even parity, and one stop
bit. The default clock and baud-rate parameters are 50 MHz and 9600 baud.

1. **What is UART?**  
   UART (Universal Asynchronous Receiver/Transmitter) is a serial
   communication interface that sends and receives data without a shared
   clock. Both ends agree on settings such as baud rate, data width, parity,
   and stop bits.

2. **Why is UART called asynchronous?**  
   The transmitter does not send a clock signal with each bit. The receiver
   uses its local clock and the agreed baud rate to locate and sample the bits.

3. **What does a typical UART frame contain?**  
   A frame has a low start bit, a configurable number of data bits, optional
   parity, and one or more high stop bits. This implementation uses a start
   bit, eight data bits, an even-parity bit, and one stop bit.

4. **What are the idle levels of UART TX and RX?**  
   Both lines are normally high when idle. A falling edge to low marks the
   beginning of a start bit.

5. **How is the start bit used by a receiver?**  
   The receiver detects the falling edge, then checks the line around the
   middle of the presumed start bit. Confirming that it is still low helps
   reject glitches before receiving data.

6. **What is baud rate?**  
   Baud rate is the number of symbols transmitted per second. For ordinary
   binary UART signaling, one symbol carries one bit, so baud rate is
   numerically equal to the bit rate.

7. **How do clock frequency and baud rate determine the bit period?**  
   The number of local clock cycles per bit is approximately
   `CLK_FREQ / BAUD_RATE`. With the defaults, `50,000,000 / 9,600` is about
   5,208 clock cycles per bit.

8. **Why should the receiver sample near the middle of a bit?**  
   The midpoint is farthest from transitions between adjacent bits. Sampling
   there gives the signal the greatest margin against timing error and edge
   uncertainty.

9. **How does a UART receiver avoid sampling every clock cycle as a new bit?**  
   It uses a baud-period counter to wait the required number of clock cycles
   between bit samples. A state machine tracks whether it is checking the
   start bit, receiving data, or checking the stop bit.

10. **Why synchronize the asynchronous RX input?**  
    RX can change near a local clock edge. A two-flop synchronizer reduces
    the chance that metastability propagates into downstream logic. It does
    not eliminate metastability or correct baud-rate mismatch.

11. **What is metastability?**  
    Metastability is an uncertain, temporary state that can occur when a
    flip-flop samples a signal too close to its setup or hold time. A
    synchronizer gives this state time to settle before the signal is used.

12. **What does the TX state machine do?**  
    It sequences through idle, start, data, parity, and stop states. In each
    active state it holds the corresponding line value for one bit period.

13. **What does the RX state machine do?**  
    It waits for a low start indication, samples the frame at baud-timed
    points, checks parity and the stop bit, and returns to idle or reports an
    error.

14. **In what order are data bits transmitted in this design?**  
    Least-significant bit first. The transmitter outputs bit 0 first and
    shifts the data register as each bit period completes.

15. **What is parity, and what parity does this design use?**  
    Parity is a simple error-detection bit calculated from the data bits.
    This design uses even parity: the parity bit is the XOR of all eight data
    bits, making the total number of ones in data plus parity even.

16. **Can parity detect every transmission error?**  
    No. It detects any odd number of bit flips in the protected data and
    parity bits, but it can miss an even number of flips. It also does not
    identify which bit was corrupted.

17. **What is the purpose of the stop bit?**  
    The stop bit returns the line to its high idle level and separates frames.
    A receiver can flag a framing error if the line is low where the stop bit
    is expected.

18. **What is a framing error?**  
    It occurs when a receiver does not observe the expected high stop-bit
    level. Possible causes include noise, mismatched baud rates, or different
    frame settings.

19. **What is the purpose of the TX busy signal?**  
    It indicates that the transmitter is sending a frame and is not idle.
    In this design, it is high in the start, data, parity, and stop states.

20. **How does the transmitter accept input data?**  
    The `t_ready` input requests a transmission. When the transmitter is idle,
    it captures `data_in` and begins a frame. The data should be stable when
    it is accepted.

21. **What does `rx_valid` indicate?**  
    It indicates that the receiver has a frame whose parity and stop bit were
    accepted. The receiving logic should use it as the qualification signal
    for `data_out`.

22. **What does `rx_error` indicate?**  
    It indicates a detected receive error, such as a bad start indication,
    parity failure, or invalid stop level. The exact timing and duration of
    status signals should be considered when integrating the receiver.

23. **Why does the design use a counter width derived from the bit period?**  
    A counter needs enough bits to represent counts up to the bit-period
    terminal value. `$clog2(BIT_PERIOD)` derives a suitable width, with a
    minimum of one bit for very small periods.

24. **What is the risk of integer division in the bit-period calculation?**  
    `CLK_FREQ / BAUD_RATE` truncates any fractional result. The resulting bit
    rate can differ slightly from the requested baud rate, so the clock and
    baud parameters should be chosen to keep the error within the link's
    tolerance.

25. **What happens if the transmitter and receiver baud rates differ?**  
    Their sampling points drift relative to the transmitted bits. A small
    mismatch may work over one frame, but a large mismatch can cause incorrect
    data samples or framing errors.

26. **Why use a baud-rate clock enable rather than generate a new clock?**  
    A clock enable keeps all state logic on the same clock, simplifying timing
    analysis and clock-domain handling. A baud counter can provide a one-cycle
    enable at each bit boundary.

27. **What does the active-low asynchronous reset do here?**  
    When `areset_n` goes low, state and registers are initialized without
    waiting for a clock edge. The `_n` suffix indicates that reset is active
    low.

28. **How would you test a UART transmitter?**  
    Drive a known byte, verify the start bit, data-bit order, parity, and stop
    bit, and check that each lasts the expected number of clock cycles. Also
    test reset and requests made while the transmitter is busy.

29. **How would you test a UART receiver?**  
    Apply valid frames with different data patterns and verify the received
    byte and status signals. Also test bad parity, a low stop bit, false start
    glitches, reset, and small timing offsets.

30. **What improvements could make this UART more robust or flexible?**  
    Useful improvements include configurable data width, parity mode, and
    stop-bit count; a fractional baud-rate generator for lower clock/baud
    ratios; explicit overrun handling; and assertions or tests for status
    timing and back-to-back frames.
