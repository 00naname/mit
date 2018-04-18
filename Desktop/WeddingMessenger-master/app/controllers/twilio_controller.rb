# -*- coding: utf-8 -*-
require "twilio-ruby"

class TwilioController < ApplicationController
  include Webhookable
 
  after_filter :set_header
  
  skip_before_action :verify_authenticity_token

  def welcome
    response = Twilio::TwiML::Response.new do |r|
      r.Play 'http://naname2ch.html.xdomain.jp/1.mp3'
      r.Redirect "/record", method: "get"
    end

    render_twiml response
  end

  def record
    response = Twilio::TwiML::Response.new do |r|
      r.Play 'http://naname2ch.html.xdomain.jp/2.mp3'
      r.Record maxLength: 60, action: "/recorded", method: "post", timeout: 15
    end

    render_twiml response
  end

  def recorded
    begin
      raise ArgumentError unless params[:RecordingSid]
      record = Record.new(recording_url: params[:RecordingUrl],
                          from: params[:From],
                          note: 'Created')
      record.save
      redirect_to "/confirm/#{record.id}"
    rescue Exception => e
      redirect_to "/confirmed"
    end    
  end

  def confirm
    record = Record.find_by(id: params[:id].to_i)
    response = Twilio::TwiML::Response.new do |r|
      r.Gather action: "/respond_to_confirm/#{record.id}", method: "post", numDigits: 1, timeout: 10 do |g|
        g.Play 'http://naname2ch.html.xdomain.jp/3.mp3'
        g.Play record.recording_url
        g.Play 'http://naname2ch.html.xdomain.jp/4.mp3'
      end
      r.Redirect "/confirm/#{params[:id]}", method: "get"
    end

    render_twiml response
  end

  def respond_to_confirm
    record = Record.find_by(id: params[:id].to_i)
    case params[:Digits]
    when "3","2"
      record.note = "Rejected"
      record.save
      redirect_to "/record"
    when "1"
      record.note = "Confirmed"
      record.save
      redirect_to "/confirmed"
    else
      redirect_to "/confirm/#{record.id}"
    end
  end

  def confirmed
    response = Twilio::TwiML::Response.new do |r|
      r.Play 'http://naname2ch.html.xdomain.jp/5.mp3'
    end

    render_twiml response
  end
end
