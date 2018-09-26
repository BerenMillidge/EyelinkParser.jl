# Main parser file... mainfunction is the parse_asc_file function

# structs

include("utils.jl")
include("csv_utils.jl")

abstract type EyelinkType end
abstract type EyeEvent <: EyelinkType end

#define ones that exist but I might not use yet
mutable struct EyelinkMessage <: EyelinkType
    time::Int
    message::AbstractString
end

mutable struct EyelinkButton <: EyelinkType
    time::Int
    button_number::Int
    state::AbstractString
end

#Now for the important ones, blocks, and eye events
mutable struct Block <: EyelinkType
    eye::AbstractString
    startTime::Int
    endTime::Int
    event_type::AbstractString
    xresolution::AbstractFloat
    yresolution::AbstractFloat
    completed::Bool
    events::Array{EyeEvent}

end

# now for the eye event times!
mutable struct Fixation <: EyeEvent
    eye::AbstractString
    startTime::Int
    endTime::Int
    duration::AbstractFloat
    average_x::AbstractFloat
    average_y::AbstractFloat
    average_pupil::AbstractFloat
    xresolution::AbstractFloat
    yresolution::AbstractFloat
    completed::Bool
end

mutable struct Saccade <: EyeEvent
    eye::AbstractString
    startTime::Int
    endTime::Int
    duration::AbstractFloat
    startX::AbstractFloat
    startY::AbstractFloat
    endX::AbstractFloat
    endY::AbstractFloat
    amplitude::AbstractFloat
    peakVelocity::AbstractFloat
    xresolution::AbstractFloat
    yresolution::AbstractFloat
    completed::Bool
end

mutable struct Blink <: EyeEvent
    eye::AbstractString
    startTime::Int
    endTime::Int
    duration::AbstractFloat
    completed::Bool
end

mutable struct EyelinkSample <: EyeEvent
    timeStamp::Int
    xPositionLeft::AbstractFloat
    yPositionLeft::AbstractFloat
    pupilSizeLeft::AbstractFloat
    xPositionRight::AbstractFloat
    yPositionRight::AbstractFloat
    pupilSizeRight::AbstractFloat
    velocityLeft::AbstractFloat
    velocityRight::AbstractFloat
    xResolution::AbstractFloat
    yResolution::AbstractFloat
end
    



function isSkippable(startElem::AbstractString)
    if startElem == "" ||
        startElem == "**" ||
        startElem == ">>>>>>>" ||
        startElem == "MSG"
        return true
    end
    return false
end

function parse_sample(elems)
    time = default_parse(elems[1], Int, -1)
    xpl = default_parse(elems[2], Float64, -1)
    ypl = default_parse(elems[3], Float64, -1)
    psl = default_parse(elems[4], Float64, -1)
    xpr = default_parse(elems[5], Float64, -1)
    ypr = default_parse(elems[6], Float64, -1)
    psr = default_parse(elems[7], Float64, -1)
    xvl = default_parse(elems[8], Float64, -1)
    yvl = default_parse(elems[9], Float64, -1)
    xvr = default_parse(elems[10], Float64, -1)
    yvr = default_parse(elems[11], Float64, -1)
    xr = default_parse(elems[12], Float64, -1)
    yr = default_parse(elems[13], Float64, -1)
    return EyelinkSample(time, xpl, ypl, psl, xpr, ypr, psr, xvl, yvl, xvr, yvr, xr, yr)
end



function parseAscFile(filename, split_events=false, merge_eyes=true, save_messages=false, subject_in_filename = true)
    
    currentBlock::Block = emptyBlock
    blockList::Array{Block} = []
    messageList::Array{EyelinkMessage} = []
    currentLeftFixation::Fixation = emptyLeftFixation
    currentRightFixation::Fixation = emptyRightFixation
    currentLeftSaccade::Saccade = emptyLeftSaccade
    currentRightSaccade::Saccade = emptyRightSaccade
    currentLeftBlink::Blink = emptyLeftBlink
    currentRightBlink::Blink = emptyRightBlink
    
    function resetCurrentEvents()
        currentLeftFixation = emptyLeftFixation
        currentRightFixation= emptyRightFixation
        currentLeftSaccade = emptyLeftSaccade
        currentRightSaccade = emptyRightSaccade
        currentLeftBlink = emptyLeftBlink
        currentRightBlink = emptyRightBlink
    end
    
    
    open(filename) do f
        val = 0
        N = 20000
        for line in eachline(f)
            val +=1
           #print("Parsing line $val")
            elems=  split(strip(line), r" |\t", keepempty=false)
            if length(elems) >=1
                firstElem = elems[1]
                if isSkippable(firstElem)
                    continue
                end
                if !(firstElem in keywordList)
                    continue
                end

                if firstElem == "START"
                    if currentBlock.completed == false
                        print(currentBlock.completed)
                        print(currentBlock)
                        throw("Previous block not completed!!!")
                    end
                    
                    resetCurrentEvents()
                    
                    time::Int = parse(Int, elems[2])
                    eye::AbstractString = convert(String, elems[3])
                    Type::AbstractString = convert(String, elems[4])
                    newBlock = Block(eye, time, -1, Type, -1, -1, false, [])
                    currentBlock = newBlock
                    push!(blockList, newBlock)
                end
                if firstElem == "END"
                    if currentBlock.completed == true
                        throw("Ending an already completed block!")
                    end
                    time = default_parse(Int, elems[2], -1)
                    Type= convert(String, elems[3])
                    currentBlock.endTime = time
                    currentBlock.completed=true
                    l = length(blockList)
                    print("Parsed block $l \n")
                    print("\n")
                end
                if firstElem == "SFIX"
                    eye = elems[2]
                    if eye == "L"
                        if currentLeftFixation.completed == false
                            throw("Left Starting an already in progress fixation")
                        end
                        newFix = Fixation(eye, default_parse(Int, elems[3],-1), -1, -1,-1,-1,-1,-1,-1,false)
                        currentLeftFixation = newFix
                        push!(currentBlock.events, newFix)
                    end
                    if eye == "R"
                        if currentRightFixation.completed == false
                            print("\n")
                            print(currentRightFixation)
                            throw("Right Starting an already in progress fixation")
                        end
                        newFix = Fixation(eye, default_parse(Int, elems[3],-1), -1, -1,-1,-1,-1,-1,-1,false)
                        currentRightFixation = newFix
                        push!(currentBlock.events, newFix)
                    end
                end
                if firstElem == "EFIX"
                    eye = elems[2]
                    if eye == "L"
                        if currentLeftFixation.completed ==true
                            throw(" Left Ending already completed fixation!")
                        end
                        currentLeftFixation.eye = eye
                        stime = parse(Int, elems[3])
                        if stime != currentLeftFixation.startTime
                            throw("Left Fixation start times do not match!")
                        end
                        currentLeftFixation.startTime = stime
                        currentLeftFixation.endTime = default_parse(Int, elems[4],-1)
                        currentLeftFixation.duration = default_parse(Float64, elems[5],-1)
                        currentLeftFixation.average_x = default_parse(Float64, elems[6],-1)
                        currentLeftFixation.average_y = default_parse(Float64, elems[7],-1)
                        currentLeftFixation.average_pupil = default_parse(Float64, elems[8],-1)
                        currentLeftFixation.completed = true
                    end
                    if eye == "R"
                        if currentRightFixation.completed==true
                            throw("Right Ending already completed fixation!")
                        end
                        currentRightFixation.eye = eye
                        stime = parse(Int, elems[3])
                        if stime != currentRightFixation.startTime
                            throw("Right Fixation start times do not match!")
                        end
                        currentRightFixation.startTime = stime
                        currentRightFixation.endTime = default_parse(Int, elems[4],-1)
                        currentRightFixation.duration = default_parse(Float64, elems[5],-1)
                        currentRightFixation.average_x = default_parse(Float64, elems[6],-1)
                        currentRightFixation.average_y = default_parse(Float64, elems[7],-1)
                        currentRightFixation.average_pupil = default_parse(Float64, elems[8],-1)
                        currentRightFixation.completed = true
                    end
                end
                if firstElem == "SSACC"
                    eye = elems[2]
                    if eye == "L"
                        if currentLeftSaccade.completed == false
                            throw("Left Starting with an already in progress saccade!")
                        end
                        stime = parse(Int, elems[3])
                        newSaccade = Saccade(String(eye), stime, -1, -1, -1,-1,-1,-1,-1,-1,-1,-1,false)
                        currentLeftSaccade = newSaccade
                        push!(currentBlock.events,newSaccade)
                    end
                    if eye == "R"
                        if currentRightSaccade.completed == false
                            throw("Left Starting with an already in progress saccade!")
                        end
                        stime = parse(Int, elems[3])
                        newSaccade = Saccade(String(eye), stime, -1, -1, -1,-1,-1,-1,-1,-1,-1,-1,false)
                        currentRightSaccade = newSaccade
                        push!(currentBlock.events,newSaccade)
                    end
                        
                end
                if firstElem == "ESACC"
                    eye = elems[2]
                    if eye == "L"
                        if currentLeftSaccade.completed == true
                            throw("Left Ending an already completed saccade!")
                        end
                        stime = parse(Int, elems[3])
                        if currentLeftSaccade.startTime != stime
                            throw("Left Saccade start times do not match!")
                        end
                        try
                            currentLeftSaccade.endTime = default_parse(Int, elems[4],-1)
                            currentLeftSaccade.duration = default_parse(Float64, elems[5],-1)
                            currentLeftSaccade.startX = default_parse(Float64, elems[6],-1)
                            currentLeftSaccade.startY = default_parse(Float64, elems[7],-1)
                            currentLeftSaccade.endX = default_parse(Float64, elems[8],-1)
                            currentLeftSaccade.endY = default_parse(Float64, elems[9],-1)
                            currentLeftSaccade.amplitude = default_parse(Float64, elems[10],-1)
                            currentLeftSaccade.peakVelocity = default_parse(Float64, elems[11],-1)
                            currentLeftSaccade.completed= true
                        catch
                            print("\n")
                            print("In catch statement!")
                            print(elems)
                            throw("Error in parsing")
                        end
                        
                    end
                    if eye == "R"
                        if currentRightSaccade.completed == true
                            throw("Right Ending an already completed saccade!")
                        end
                        stime = parse(Int, elems[3])
                        if currentRightSaccade.startTime != stime
                            throw("Right Saccade start times do not match!")
                        end
                        currentRightSaccade.endTime = default_parse(Int, elems[4],-1)
                        currentRightSaccade.duration = default_parse(Float64, elems[5],-1)
                        currentRightSaccade.startX = default_parse(Float64, elems[6],-1)
                        currentRightSaccade.startY = default_parse(Float64, elems[7],-1)
                        currentRightSaccade.endX = default_parse(Float64, elems[8],-1)
                        currentRightSaccade.endY = default_parse(Float64, elems[9],-1)
                        currentRightSaccade.amplitude = default_parse(Float64, elems[10],-1)
                        currentRightSaccade.peakVelocity = default_parse(Float64, elems[11],-1)
                        currentRightSaccade.completed= true
                    end
                end
                if firstElem == "SBLINK"
                    eye = elems[2]
                    if eye == "L"
                        if currentLeftBlink.completed == false
                            throw("Left Startin a blink with one already in progress")
                        end
                        stime = default_parse(Int, elems[3],-1)
                        newBlink = Blink(String(eye), stime, -1, -1, false)
                        currentLeftBlink = newBlink
                        push!(currentBlock.events,newBlink)
                    end
                    if eye == "R"
                        if currentRightBlink.completed == false
                            throw("Right Startin a blink with one already in progress")
                        end
                        stime = default_parse(Int, elems[3],-1)
                        newBlink = Blink(String(eye), stime, -1, -1, false)
                        currentRightBlink = newBlink
                        push!(currentBlock.events,newBlink)
                    end
                end
                if firstElem == "EBLINK"
                    eye = elems[2]
                    if eye == "L"
                        if currentLeftBlink.completed == true
                            throw("Left Ending with an already completed blink!")
                        end
                        stime = parse(Int, elems[3])
                        if currentLeftBlink.startTime != stime
                            throw("Left Start times for blink do not match!")
                        end
                        currentLeftBlink.endTime = default_parse(Int, elems[4],-1)
                        currentLeftBlink.duration = default_parse(Float64, elems[5],-1)
                        currentLeftBlink.completed = true
                    end
                    if eye == "R"
                        if currentRightBlink.completed == true
                            throw("Left Ending with an already completed blink!")
                        end
                        stime = parse(Int, elems[3])
                        if currentRightBlink.startTime != stime
                            throw("Right Start times for blink do not match!")
                        end
                        currentRightBlink.endTime = default_parse(Int, elems[4],-1)
                        currentRightBlink.duration = default_parse(Float64, elems[5],-1)
                        currentRightBlink.completed = true
                    end
                end
                if save_messages == true
                    if firstElem == "MSG"
                        time = parse(Int,elems[2])
                        message_string = concatSubstrings(elems[3:length(elems)])
                        message = Message(time, message_string)
                        push!(messageList, message)
                    end
                end
               
                if typeof(tryparse(Int, firstElem)) != Nothing
                        # this means it's an integer
                        print("SAMPLE PARSED! $val \n")
                        print(elems)
                        print(firstElem)
                        print(typeof(tryparse(Int, firstElem)))
                        sample = parse_sample(elems)
                        push!(blockList.events, sample)
                end

            end
            
        end
    end
    print("Parsed File!")
    write_type_split_csv("Parser_test",blockList, ",")
end
            
            
