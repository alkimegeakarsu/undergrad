library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity design is
    Port ( i_clk : in STD_LOGIC; -- 100MHz clock
-- Inputs
 -- User inputs
           i_motion : STD_LOGIC; -- Rightmost switch
           i_speedSetting : STD_LOGIC_VECTOR (1 downto 0); -- First two switches
           i_distanceSetting : STD_LOGIC_VECTOR (1 downto 0); -- Second two switches
 -----
 -- Sensor inputs
           i_sensorIR_ld : in STD_LOGIC; -- Infrared left downward
           i_sensorIR_rd : in STD_LOGIC; -- Infrared right downward
           i_sensorIR_lf : in STD_LOGIC; -- Infrared left forward
           i_sensorIR_rf : in STD_LOGIC; -- Infrared right forward
           i_sensorUS_echo : in STD_LOGIC; -- Ultrasonic echo
 -----
-----
-- Outputs
 -- DC motor outputs
           o_motorDC_lf : out STD_LOGIC; -- Left forward
           o_motorDC_lb : out STD_LOGIC; -- Left backward
           o_motorDC_rf : out STD_LOGIC; -- Right forward
           o_motorDC_rb : out STD_LOGIC; -- Right backward
 -----
 -- Servo motor output
           o_motorServo_PWM : out STD_LOGIC; -- PWM signal for servo motor
 -----
 -- Ultrasonic sensor output
           o_sensorUS_trig : out STD_LOGIC; -- Ultrasonic trigger
 -----
 -- LED output
           o_leds : out STD_LOGIC_VECTOR (15 downto 0); -- LED output
 -----
 -- Display outputs
           o_display_anodeOn : out STD_LOGIC_VECTOR (3 downto 0); -- Which digit to give power to
           o_display_cathodePattern : out STD_LOGIC_VECTOR (6 downto 0) -- Which pattern to display
 ------
-----
          );
end design;
architecture Behavioral of design is
-- Signals
 -- Detection
    signal detection_counter : INTEGER range 0 to 150000000 := 0; -- 1 second counter that starts after detection
    signal detection_side : STD_LOGIC; -- The side teh detected obstacle is on
    signal detection_type : STD_LOGIC; -- The sensor type that detected the obstacle
 -----
 -- DC motors
    signal motorDC_PWMdutyCycle : INTEGER range 0 to 1000000 := 0; -- Duty cycle
    signal motorDC_PWMcounter : INTEGER range 0 to 1000000 := 0; -- 100Hz
    signal motorDC_PWMsignal : STD_LOGIC := '0'; -- Signal to give to DC motors
 -----
 -- Servo motor
    signal motorServo_PWMcounter : INTEGER range 0 to 2000000 := 0; -- 50Hz
    signal motorServo_PWMdutyCycle : INTEGER range 45284 to 236010 := 45284; -- Min: 34688 Max: 262500, 1,059.590697674419 per degree, 45284 - 236010 frontal 180 degrees, 140647 straight
    signal motorServo_dirOfRotation : STD_LOGIC := '1'; -- Direction of rotation OR whether motorServo_PWMdutyCycle increases or decreases
    signal motorServo_spdOfRotCounter : INTEGER range 0 to 500; -- How fast the platform rotates OR the time between each incrementation of motorServo_PWMdutyCycle threshold
 -----
 -- US sensor
    signal sensorUS_mainCounter : INTEGER range 0 to 2500000 := 0; -- 50ms US measurment time (20Hz)
    signal sensorUS_echoCounter : INTEGER range 0 to 2500000 := 0; -- Echo timer
    signal sensorUS_distanceCM : INTEGER range 0 to 400 :=0; -- Detection distance
 ------
 -- Display
    signal display_write : STD_LOGIC_VECTOR (15 downto 0); -- What to write on the display
    signal display_value : STD_LOGIC_VECTOR (3 downto 0); -- Which digit pattern to display
    signal display_refresh : STD_LOGIC_VECTOR (19 downto 0); -- For generating LED refresh interval
    signal display_digitActivate : STD_LOGIC_VECTOR (1 downto 0); -- Which digit to give power to
    signal display_idleStageCounter : INTEGER range 0 to 6666666 := 6666666; -- How often should the digits change
    signal display_reverse : STD_LOGIC; -- Animation direction
    signal display_stage : INTEGER range 0 to 15; -- Animation stage
 -----
-----
begin
-- Combinational logic
o_leds(15) <= i_speedSetting(1);
o_leds(14) <= i_speedSetting(0);

o_leds(13) <= i_distanceSetting(1);
o_leds(12) <= i_distanceSetting(0);

o_leds(0) <= i_motion;
------
process(i_clk)
begin
    if rising_edge(i_clk) then -- Sequential logic
-- Display
 -- Animation
        if display_idleStageCounter < 6666666 then
            display_idleStageCounter <= display_idleStageCounter + 1;
        else
            display_idleStageCounter <= 0;
        end if;
        
        if display_idleStageCounter = 3333333 then
            if display_stage = 0 AND display_reverse = '1' then
                display_reverse <= '0';
            elsif display_stage = 15 AND display_reverse = '0' then
                display_reverse <= '1';
            elsif display_reverse = '0' then
                display_stage <= display_stage + 1;
            elsif display_reverse = '1' then
                display_stage <= display_stage - 1;
            end if;
        elsif display_idleStageCounter = 6666665 then
            display_idleStageCounter <= 0;
            case display_stage is
				when 0 => display_write <= "1111111111111111";
				when 1 => display_write <= "1010111111111111";
				when 2 => display_write <= "1111101011111111";
				when 3 => display_write <= "1111111110101111";
				when 4 => display_write <= "1111111111111010";
				when 5 => display_write <= "1111111111111011";
				when 6 => display_write <= "1111111111111100";
				when 7 => display_write <= "1111111111001111";
				when 8 => display_write <= "1111110011111111";
				when 9 => display_write <= "1100111111111111";
				when 10 => display_write <= "1101111111111111";
				when 11 => display_write <= "1110111111111111";
				when 12 => display_write <= "1111111011111111";
				when 13 => display_write <= "1111111111101111";
				when 14 => display_write <= "1111111111111110";
				when 15 => display_write <= "1111111111111111";
				when others => display_write <= "0001001000110100";
			end case;
		end if;
 ------
 -- Refresh and activate
        display_refresh <= display_refresh + 1;
        display_digitActivate <= display_refresh (19 downto 18);
 ------
 -- Value table
        case display_value is
            when "0000" => o_display_cathodePattern <= "0000001"; -- "S"     
            when "0001" => o_display_cathodePattern <= "1001111"; -- "P" 
            when "0010" => o_display_cathodePattern <= "0010010"; -- "E" 
            when "0011" => o_display_cathodePattern <= "0000110"; -- "d" 
            when "0100" => o_display_cathodePattern <= "1001100"; -- "r" 
            when "0101" => o_display_cathodePattern <= "0100100"; -- "a" 
            when "0110" => o_display_cathodePattern <= "0100000"; -- "n" 
            when "0111" => o_display_cathodePattern <= "0001111"; -- "g" 
            when "1000" => o_display_cathodePattern <= "1010101"; -- ""     
            when "1001" => o_display_cathodePattern <= "0101010"; -- "" 
            when "1010" => o_display_cathodePattern <= "0111111"; -- "pattern 1"
            when "1011" => o_display_cathodePattern <= "1011111"; -- "pattern 2"
            when "1100" => o_display_cathodePattern <= "1111110"; -- "pattern 3"
            when "1101" => o_display_cathodePattern <= "1111011"; -- "pattern 4"
            when "1110" => o_display_cathodePattern <= "1110111"; -- "pattern 5"
            when "1111" => o_display_cathodePattern <= "1111111"; -- "pattern 6"
            when others => o_display_cathodePattern <= "1111110"; -- "-"
        end case;
 ------
 -- What to display
        case display_digitActivate is
            when "00" => o_display_anodeOn <= "0111"; -- Leftmost digit (MSB)
                display_value <= display_write(15 downto 12);
            when "01" => o_display_anodeOn <= "1011";
                display_value <= display_write(11 downto 8);
            when "10" => o_display_anodeOn <= "1101";
                display_value <= display_write(7 downto 4);
            when "11" => o_display_anodeOn <= "1110"; -- Rightmost digit (LSB)
                display_value <= display_write(3 downto 0);
        end case;
 ------
------
-- Servo motor global code
        if motorServo_PWMcounter < 2000000 then
            motorServo_PWMcounter <= motorServo_PWMcounter + 1;
        else
            motorServo_PWMcounter <= 0;
        end if;
                
        if motorServo_spdOfRotCounter < 300 then
            motorServo_spdOfRotCounter <= motorServo_spdOfRotCounter + 1;
        else
            motorServo_spdOfRotCounter <= 0;
        end if;
------
        if i_motion = '1' then -- If the robot is in motion
-- DC motors PWM generation
            if motorDC_PWMcounter < 1000000 then
                motorDC_PWMcounter <= motorDC_PWMcounter + 1;
            else
                motorDC_PWMcounter <= 0;
            end if;
            
            if i_speedSetting = "00" then
                motorDC_PWMdutyCycle <= 0;
            elsif i_speedSetting = "01" then
                motorDC_PWMdutyCycle <= 333333;
            elsif i_speedSetting = "10" then
                motorDC_PWMdutyCycle <= 666666;
            else
                motorDC_PWMdutyCycle <= 1000000;
            end if;
            
            if motorDC_PWMcounter < motorDC_PWMdutyCycle then
                motorDC_PWMsignal <= '1';
            else
                motorDC_PWMsignal <= '0';
            end if;
------
            if detection_counter = 0 then -- If no object is detected, normal operation
-- LEDs
                o_leds(10) <= '0';
                o_leds(9) <= '0';
                o_leds(8) <= '0';
                o_leds(7) <= '0';
                o_leds(6) <= '0';
                o_leds(5) <= '0';
                o_leds(4) <= '0';
                o_leds(3) <= '0';
                o_leds(2) <= '0';
------
-- DC motors assignment
                o_motorDC_lf <= motorDC_PWMsignal;
                o_motorDC_rf <= motorDC_PWMsignal;
                o_motorDC_lb <= '0';
                o_motorDC_rb <= '0';
------
-- Servo motor
                if motorServo_spdOfRotCounter = 0 then
                    if motorServo_PWMdutyCycle <= 45284 then
                        motorServo_dirOfRotation <= '1';
                    elsif motorServo_PWMdutyCycle >= 236010 then
                        motorServo_dirOfRotation <= '0';
                    end if;
                        
                    if motorServo_dirOfRotation = '1' then
                        motorServo_PWMdutyCycle <= motorServo_PWMdutyCycle + 1;
                    else
                        motorServo_PWMdutyCycle <= motorServo_PWMdutyCycle - 1;
                    end if;
                end if;
                
                if motorServo_PWMcounter < motorServo_PWMdutyCycle then
                    o_motorServo_PWM <= '1';
                else
                    o_motorServo_PWM <= '0';
                end if;
------
-- US sensor
                if sensorUS_mainCounter < 2500000 then -- Main US counter incrementation
                    sensorUS_mainCounter <= sensorUS_mainCounter + 1;
                else -- mainCounter and echoCounter reset
                    sensorUS_mainCounter <= 0;
                    sensorUS_echoCounter <=0;
                end if;
                
                if sensorUS_mainCounter < 1000 then -- Trigger signal
                    o_sensorUS_trig <= '1';
                else
                    o_sensorUS_trig <= '0';
                end if;
                
                if i_sensorUS_echo = '1' then -- Echo timer incrementation
                    sensorUS_echoCounter <= sensorUS_echoCounter + 1;
                end if;
                
                if sensorUS_mainCounter = 2499998 then
                    if (sensorUS_echoCounter / 5830) <= sensorUS_distanceCM then
                        detection_counter <= detection_counter + 1;
                        detection_type <= '1';
                        if motorServo_PWMdutyCycle < 140647 then -- left side
                            detection_side <= '1';
                        else
                            detection_side <= '0'; -- right side
                        end if;
                    end if;
                end if;
------
-- IR sensor
                if i_sensorIR_ld = '1' OR i_sensorIR_lf = '0' then
                    detection_counter <= detection_counter + 1;
                    detection_side <= '0';
                    detection_type <= '0';
                elsif i_sensorIR_rd = '1' OR i_sensorIR_rf = '0' then
                    detection_counter <= detection_counter + 1;
                    detection_side <= '1';
                    detection_type <= '0';
                end if;
------
            else -- If something is detected, counter starts, avoidance sequence initiates
-- LEDs
                o_leds(10) <= '1';
                o_leds(9) <= '1';
                o_leds(8) <= '1';
                o_leds(7) <= '1';
                o_leds(6) <= '1';
                o_leds(5) <= '1';
                o_leds(4) <= '1';
                o_leds(3) <= '1';
                o_leds(2) <= '1';
------
-- Counter incrementation
                if detection_counter < 150000000 then
                    detection_counter <= detection_counter + 1;
                else
                    detection_counter <= 0;
                end if;
------
-- Servo control
                if detection_type = '1' then -- Stop servo
                    o_motorServo_PWM <= '0';
                else -- Normal servo operation
                    if motorServo_spdOfRotCounter = 0 then
                        if motorServo_PWMdutyCycle <= 45284 then
                            motorServo_dirOfRotation <= '1';
                        elsif motorServo_PWMdutyCycle >= 236010 then
                            motorServo_dirOfRotation <= '0';
                        end if;
                            
                        if motorServo_dirOfRotation = '1' then
                            motorServo_PWMdutyCycle <= motorServo_PWMdutyCycle + 1;
                        else
                            motorServo_PWMdutyCycle <= motorServo_PWMdutyCycle - 1;
                        end if;
                    end if;
                    
                    if motorServo_PWMcounter < motorServo_PWMdutyCycle then
                        o_motorServo_PWM <= '1';
                    else
                        o_motorServo_PWM <= '0';
                    end if;
                    end if;
------
-- Maneuver
                if detection_counter < 20000000 then -- Braking stage
                    o_motorDC_lf <= motorDC_PWMsignal;
                    o_motorDC_rf <= motorDC_PWMsignal;
                    o_motorDC_lb <= motorDC_PWMsignal;
                    o_motorDC_rb <= motorDC_PWMsignal;
                elsif detection_counter < 105000000 then -- Reversing stage
                    o_motorDC_lf <= '0';
                    o_motorDC_rf <= '0';
                    o_motorDC_lb <= motorDC_PWMsignal;
                    o_motorDC_rb <= motorDC_PWMsignal;
                else -- Rotation stage
                    if detection_side = '0' then -- Left side
                        o_motorDC_lf <= motorDC_PWMsignal;
                        o_motorDC_rf <= '0';
                        o_motorDC_lb <= '0';
                        o_motorDC_rb <= motorDC_PWMsignal;
                    else -- Right side
                        o_motorDC_lf <= '0';
                        o_motorDC_rf <= motorDC_PWMsignal;
                        o_motorDC_lb <= motorDC_PWMsignal;
                        o_motorDC_rb <= '0';
                    end if;
                end if;
------
            end if;
        else -- If the robot is not in motion
            detection_counter <= 0;
-- LEDs
                o_leds(10) <= '0';
                o_leds(9) <= '0';
                o_leds(8) <= '0';
                o_leds(7) <= '0';
                o_leds(6) <= '0';
                o_leds(5) <= '0';
                o_leds(4) <= '0';
                o_leds(3) <= '0';
                o_leds(2) <= '0';
------
-- DC motors
            o_motorDC_lf <= '0';
            o_motorDC_rf <= '0';
            o_motorDC_lb <= '0';
            o_motorDC_rb <= '0';
------
-- Servo
            motorServo_PWMdutyCycle <= 140647; -- Straight forward servo
            if motorServo_PWMcounter < motorServo_PWMdutyCycle then
                o_motorServo_PWM <= '1';
            else
                o_motorServo_PWM <= '0';
            end if;
------
-- Distance selection to CM
            case i_distanceSetting is
                when "00" => sensorUS_distanceCM <= 20;
                when "01" => sensorUS_distanceCM <= 25;
                when "10" => sensorUS_distanceCM <= 30;
                when "11" => sensorUS_distanceCM <= 35;
                when others => sensorUS_distanceCM <= 10;
            end case;
------
        end if;
    end if;
end process;
end Behavioral;



































