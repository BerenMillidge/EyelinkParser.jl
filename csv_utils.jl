# CSV writing and reading utility functions for the parser



function write_type_split_csv(basename::AbstractString, blockList::Array{Block}, delim::AbstractString)
    fixColnames = ["Eye", "StartTime", "EndTime", "Duration", "AverageX","AverageY", "AveragePupil", "XResolution","YResolution", "Completed"]
    saccColnames = ["Eye", "StartTime","EndTime","Duration","StartX","StartY","EndX","EndY","Amplitude","PeakVelocity","XResolution","YResolution","Completed"]
    blinkColnames = ["Eye","StartTime","EndTime", "Duration", "Completed"]
    fixname = basename * "_Fixations.csv"
    saccname = basename * "_Saccades.csv"
    blinkname = basename * "_Blinks.csv"
    fixf = create_open_file(fixname)
    saccf = create_open_file(saccname)
    blinkf = create_open_file(blinkname)
    
    #write the colum headers
    write_csv_line(fixf, fixColnames, delim)
    write_csv_line(saccf, saccColnames, delim)
    write_csv_line(blinkf, blinkColnames,delim)

    for block in blockList
        for evt in block.events
            if typeof(evt) == typeof(emptyLeftFixation)
                write_csv_line(fixf, getfields(evt), delim)
            end
            if typeof(evt) == typeof(emptyLeftSaccade)
                write_csv_line(saccf, getfields(evt), delim)
            end
            if typeof(evt) == typeof(emptyLeftBlink)
                write_csv_line(blinkf, getfields(evt), delim)
            end
        end
    end 
        
    close(fixf)
    close(saccf)
    close(blinkf)
end


function write_merged_csv_line(f::IOStream, evt::EyeEvent, fnames::Vector{Symbol}, delim::AbstractString)
    t = typeof(evt)
    fields = fieldnames(t)
    s = string(t) * delim
    for i in 1:length(fnames)
        field = fnames[i]
        if field in fields
            val = getfield(evt, field)
            if val != -1
                s = s * string(val) * delim
            else
                s = s *delim
            end
        end
        if !(field in fields)
            s = s * delim
        end
    end
    s = chop(s)
    s = s * "\n"
    write(f,s)
end

function write_merged_csv(basename::AbstractString, blockList::Array{Block}, delim::AbstractString)
    if !endswith(basename, ".csv")
        basename  = basename * ".csv"
    end
    fi= create_open_file(basename)
    fieldnames = [:eye, :startTime, :endTime, :duration, :startX, :startY, :endX, :endY, :average_x, :average_y, :average_pupil, :amplitude, :peakVelocity, :xresolution, :yresolution, :completed]
    colnames = ["Type", "Eye", "StartTime", "EndTime", "Duration","StartX", "StartY","EndX","EndY","AverageX","AverageY","AveragePupil","Amplitude","PeakVelocity","XResolution", "YResolution","Completed"]
    write_csv_line(fi, colnames, delim)
    for block in blockList
        for evt in block.events
            write_merged_csv_line(fi, evt, fieldnames, delim)
        end
    end 

end

function write_messages_csv(basename::AbstractString, messageList::Array{EyelinkMessage}, delim::AbstractString)
    if !endswith(basename, ".csv")
        basename  = basename * ".csv"
    end
    fi= create_open_file(basename)
    colnames= ["Type", "Message"]
    write_csv_line(fi, colnames, delim)
    for message in messageList
        write_csv_line(fi, getfields(message),delim)
    end
    close(fi)
end
    

function write_csv_line(f::IOStream, elems, delim::AbstractString)
    s = ""
    for elem in elems
        if elem == -1
            s = s * delim 
        else
            s = s *string(elem) * delim
        end
    end
    s = chop(s)
    s = s * "\n"
    write(f, s)
end

function read_csv_line(line::AbstractString, sep::AbstractString)
    arr = split(strip(line), sep)
    return arr
end
