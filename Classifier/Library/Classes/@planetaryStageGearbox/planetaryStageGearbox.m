classdef planetaryStageGearbox < connectionElement
    
    properties ( Access = protected )
        z1                         % the 1st shaft teeth count
        z2                         % the 2nd shaft teeth count
        planetWheelNumber          % number of the planet wheel
        teethNumberRingGear        % teeth number of the ring gear
        positionPlanetWheel 
    end
    
    methods

        function myGearing = planetaryStageGearbox(myElementType, myClassType, myName, myShaftFreq, myZ1, myZ2, ...
                                                   myPlanetWheelNumber, myTeethNumberRingGear, myPositionPlanetWheel)
            myId = '11';
            myGearing = myGearing@connectionElement(myElementType, myClassType, myName, myShaftFreq, myId);

            if nargin == 9

                myGearing.z1 = myZ1;
                myGearing.z2 = myZ2;
                myGearing.planetWheelNumber = myPlanetWheelNumber;
                myGearing.teethNumberRingGear = myTeethNumberRingGear;
                myGearing.positionPlanetWheel = myPositionPlanetWheel;
            else
                myGearing.z1 = [];
                myGearing.z2 = [];
            end
        end

        function [sunFreq , carrierFreq, satellitesFreq, diffFreq, gearMeshFreqSun, ...
                  gearMeshFreqSatellites, SPFS, SPFG] = getGearingFreq(myGearing, shaftFreq)
            % z2Sun - teeth number of sun ring 
            % z1Satellites - teeth number of satellites

            % SPFG - satellites pass frequency ring gear
            % SPFS - satellites pass frequency ring sun
            % sunFreq - sun frequency
            % carrierFreq - carrier frequency
            % satellitesFreq - satellites frequency
            % diffFreq - difference frequency
             
            if myGearing.positionPlanetWheel == 1

                z1Satellites = myGearing.z1;
                z2Sun = myGearing.z2;

                [z1Satellites, z2Sun, myGearing.teethNumberRingGear] = ...
                    myGearing.checkAllTeethNumber(z1Satellites, z2Sun, myGearing.teethNumberRingGear);
                
                carrierFreq = shaftFreq;
                sunFreq = carrierFreq * 2 * ((z2Sun + z1Satellites)/z2Sun);
            else

                z1Satellites = myGearing.z2;
                z2Sun = myGearing.z1;

                [z1Satellites, z2Sun, myGearing.teethNumberRingGear] = ...
                    myGearing.checkAllTeethNumber(z1Satellites, z2Sun, myGearing.teethNumberRingGear);
                
                sunFreq = shaftFreq;
                carrierFreq = sunFreq * (z2Sun / (2*(z2Sun + z1Satellites)));
            end

            satellitesFreq = carrierFreq * (myGearing.teethNumberRingGear / z1Satellites);
            diffFreq = abs(carrierFreq - sunFreq);
            gearMeshFreqSun = sunFreq * z2Sun;
            gearMeshFreqSatellites = satellitesFreq * z1Satellites;

            SPFS = myGearing.planetWheelNumber * diffFreq;
            SPFG = myGearing.planetWheelNumber * carrierFreq;
        end

        function basicFreqList = getBasicFreqList(myGearing)
            
            [sunFreq , carrierFreq, satellitesFreq, diffFreq, gearMeshFreqSun, ...
                  gearMeshFreqSatellites, SPFS, SPFG] = getGearingFreq(myGearing, myGearing.shaftFreq);
              
            basicFreqList = [20, sunFreq, {'sunFreq'}; ...
                             21, carrierFreq, {'carrierFreq'}; ...
                             22, satellitesFreq, {'satellitesFreq'}; ...
                             23, diffFreq, {'diffFreq'};
                             24, gearMeshFreqSun, {'gearMeshFreqSun'};
                             25, gearMeshFreqSatellites, {'gearMeshFreqSatellites'};
                             26, SPFS, {'SPFS'};
                             27, SPFG, {'SPFG'};];
        end
    
    end
    
    methods(Static)
        
        % CHECKALLTEETHNUMBER function checking correct number of teeth
        function [z1Satellites, z2Sun, teethNumberRingGear] = checkAllTeethNumber(z1Satellites, z2Sun, teethNumberRingGear)
            iLoger = loger.getInstance();
            
            % The expression  teethNumberRingGear = sunTeeth + (2* satellitesTeeth)
            % should be
            if z1Satellites > 0 && z2Sun > 0 && teethNumberRingGear > 0
                
                if teethNumberRingGear ~= z2Sun + (2 * z1Satellites)
                    printWarning(iLoger, 'Not correct input data of planetary stage gearbox');
                end
            else
                if  teethNumberRingGear == 0
                    
                    teethNumberRingGear = z2Sun + (2 * z1Satellites);
                elseif z2Sun == 0
                    
                    z2Sun = teethNumberRingGear - (2 * z1Satellites);
                else
                    z1Satellites = (teethNumberRingGear - z2Sun) / 2;

                    if floor(z1Satellites) ~= z1Satellites
                        z1Satellites = round(z1Satellites);
                        printWarning(iLoger, 'Not correct input data of planetary stage gearbox');
                    end
                end
            end
        end
    end
end

