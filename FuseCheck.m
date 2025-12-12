function [inValidM2,fuse_length] = FuseCheck(w_span, num_passengers, section_length, numDucks)

    inValidM2 = 0;
    
    %fuse configuration
    AvionicsSpace = 0.3;
    BannerMechanism = 0.005;
    % section_length = .190;
    num_ducks_perSection = numDucks;
    
    % max fuse legnth allowed
    Max_fuse_length = w_span*1.5;
    Min_fuse_length = w_span * 0.85;
    
    num_sections_needed = ceil(num_passengers / num_ducks_perSection);
    
    % Compute fuse length requirement
    fuse_length = AvionicsSpace + BannerMechanism + num_sections_needed * section_length;
    if fuse_length > Max_fuse_length
        inValidM2 = 1; % invalid if too long
    end
    if fuse_length < Min_fuse_length
        fuse_length = Min_fuse_length;
    end

end